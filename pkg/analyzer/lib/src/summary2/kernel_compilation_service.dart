// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/compiler/request_channel.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/utilities/uri_cache.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as package_path;

/// Service for compiling Dart into kernel bytes.
///
/// It is implemented using `frontend_server` from the Dart SDK, and the
/// running executable is expected to be `<sdk>/bin/dart` process.
class KernelCompilationService {
  /// The lock that must be acquired to access [_currentInstance].
  static final _Lock _lock = _Lock();

  /// The current running `frontend_server` instance.
  static _FrontEndServerInstance? _currentInstance;

  /// The timer scheduled to invoke [dispose] if no more compilations.
  static Timer? _disposeDelayTimer;

  /// Return an instance of the front-end server, starting it if necessary.
  ///
  /// Must be invoked with the [_lock] acquired.
  static Future<_FrontEndServerInstance> get _instance async {
    final instance = _currentInstance;
    if (instance != null) {
      return instance;
    }

    final sdkPaths = _computeSdkPaths();

    final socketCompleter = Completer<io.Socket>();
    final serverSocket = await _loopbackServerSocket();
    serverSocket.listen((socket) async {
      socketCompleter.complete(socket);
    });

    final host = serverSocket.address.address;
    final addressStr = '$host:${serverSocket.port}';

    final io.Process process;
    if (io.File(sdkPaths.frontEndAotSnapshot).existsSync()) {
      process = await io.Process.start(sdkPaths.aotRuntime, [
        sdkPaths.frontEndAotSnapshot,
        '--binary-protocol-address=$addressStr',
      ]);
    } else {
      // AOT snapshots cannot be generated on IA32, so we need this fallback
      // branch until support for IA32 is dropped (https://dartbug.com/49969).
      process = await io.Process.start(io.Platform.resolvedExecutable, [
        sdkPaths.frontEndSnapshot,
        '--binary-protocol-address=$addressStr',
      ]);
    }

    // When the process exits, we should not try to continue using it.
    // ignore: unawaited_futures
    process.exitCode.then((_) {
      _currentInstance = null;
    });

    final socket = await socketCompleter.future;
    final requestChannel = RequestChannel(socket);

    // Put the platform dill.
    final platformDillPath = sdkPaths.platformDill;
    final platformDillBytes = io.File(platformDillPath).readAsBytesSync();
    await requestChannel.sendRequest<void>('dill.put', {
      'uri': 'dill:vm',
      'bytes': platformDillBytes,
    });

    return _currentInstance =
        _FrontEndServerInstance(process, serverSocket, socket, requestChannel);
  }

  KernelCompilationService._();

  /// Compiles the file with the [path] into kernel bytes. This file is
  /// compiled as a program (script), so it must have the `main` function.
  ///
  /// Compilation will cancel any scheduled [disposeDelayed], so it should
  /// be requested again using [dispose] or [disposeDelayed].
  static Future<Uint8List> compile({
    required MacroFileSystem fileSystem,
    required String path,
  }) {
    _disposeDelayTimer?.cancel();
    _disposeDelayTimer = null;

    return _lock.synchronized(() async {
      final instance = await _instance;
      final requestChannel = instance.requestChannel;

      MacroFileEntry uriStrToFile(Object? uriStr) {
        final uri = uriCache.parse(uriStr as String);
        final path = fileSystem.pathContext.fromUri(uri);
        return fileSystem.getFile(path);
      }

      // Configure file system requests.
      requestChannel.add('file.exists', (uriStr) async {
        return uriStrToFile(uriStr).exists;
      });
      requestChannel.add('file.readAsBytes', (uriStr) async {
        final content = uriStrToFile(uriStr).content;
        return const Utf8Encoder().convert(content);
      });
      requestChannel.add('file.readAsStringSync', (uriStr) async {
        return uriStrToFile(uriStr).content;
      });

      // Now we can compile.
      return await requestChannel.sendRequest<Uint8List>('kernelForProgram', {
        'sdkSummary': 'dill:vm',
        'uri': fileSystem.pathContext.toUri(path).toString(),
      });
    });
  }

  /// Stops the running `frontend_server` process.
  static Future<void> dispose() {
    return _lock.synchronized(() async {
      final instance = _currentInstance;
      if (instance != null) {
        _currentInstance = null;
        // We don't expect any answer, the process will stop.
        // ignore: unawaited_futures
        instance.requestChannel.sendRequest<void>('exit', {});
        instance.socket.destroy();
        // This socket is bound to a fresh port, we don't need it.
        // ignore: unawaited_futures
        instance.serverSocket.close();
        instance.process.kill();
      }
    });
  }

  /// Schedules [dispose] invocation, if not interrupted by [compile].
  @visibleForTesting
  static void disposeDelayed(Duration timeout) {
    _disposeDelayTimer?.cancel();
    _disposeDelayTimer = Timer(timeout, () {
      dispose();
    });
  }

  static _SdkPaths _computeSdkPaths() {
    // Check for google3.
    final runFiles = io.Platform.environment['RUNFILES'];
    if (runFiles != null) {
      final aotRuntimePath = io.Platform.environment['AOT_RUNTIME_PATH']!;
      final frontServerPath = io.Platform.environment['FRONTEND_SERVER_PATH']!;
      final frontendServerAotSnapshotPath =
          io.Platform.environment['FRONTEND_SERVER_AOT_SNAPSHOT_PATH']!;
      final platformDillPath = io.Platform.environment['PLATFORM_DILL_PATH']!;
      return _SdkPaths(
        aotRuntime: package_path.join(runFiles, aotRuntimePath),
        frontEndSnapshot: package_path.join(runFiles, frontServerPath),
        frontEndAotSnapshot:
            package_path.join(runFiles, frontendServerAotSnapshotPath),
        platformDill: package_path.join(runFiles, platformDillPath),
      );
    }

    final executablePath = io.Platform.resolvedExecutable;
    final binPath = package_path.dirname(executablePath);
    final sdkPath = package_path.dirname(binPath);

    return _SdkPaths(
      aotRuntime: package_path.join(binPath, 'dartaotruntime'),
      frontEndSnapshot: package_path.join(
          binPath, 'snapshots', 'frontend_server.dart.snapshot'),
      frontEndAotSnapshot: package_path.join(
          binPath, 'snapshots', 'frontend_server_aot.dart.snapshot'),
      platformDill: package_path.join(
          sdkPath, 'lib', '_internal', 'vm_platform_strong.dill'),
    );
  }

  static Future<io.ServerSocket> _loopbackServerSocket() async {
    try {
      return await io.ServerSocket.bind(io.InternetAddress.loopbackIPv6, 0);
    } on io.SocketException catch (_) {
      return await io.ServerSocket.bind(io.InternetAddress.loopbackIPv4, 0);
    }
  }
}

class _FrontEndServerInstance {
  final io.Process process;
  final io.ServerSocket serverSocket;
  final io.Socket socket;
  final RequestChannel requestChannel;

  _FrontEndServerInstance(
    this.process,
    this.serverSocket,
    this.socket,
    this.requestChannel,
  );
}

/// Simple non-reentrant lock.
class _Lock {
  Future<void>? _last;

  Future<T> synchronized<T>(FutureOr<T> Function() f) async {
    final previous = _last;
    final completer = Completer<void>.sync();
    _last = completer.future;
    try {
      if (previous != null) {
        await previous;
      }

      final result = f();
      if (result is Future) {
        return await result;
      } else {
        return result;
      }
    } finally {
      if (identical(_last, completer.future)) {
        _last = null;
      }
      completer.complete();
    }
  }
}

class _SdkPaths {
  final String aotRuntime;
  final String frontEndSnapshot;
  final String frontEndAotSnapshot;
  final String platformDill;

  _SdkPaths({
    required this.aotRuntime,
    required this.frontEndSnapshot,
    required this.frontEndAotSnapshot,
    required this.platformDill,
  });
}
