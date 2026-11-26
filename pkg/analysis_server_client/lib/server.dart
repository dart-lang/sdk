// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/src/server_base.dart';
import 'package:path/path.dart';

export 'package:analysis_server_client/src/server_base.dart'
    show NotificationProcessor;

/// Instances of the class [Server] manage a server process,
/// and facilitate communication to and from the server.
///
/// Clients may not extend, implement or mix-in this class.
class Server extends ServerBase {
  /// Server process object, or `null` if server hasn't been started yet
  /// or if the server has already been stopped.
  Process? _process;

  /// The stderr subscription or `null` if either
  /// [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String>? _stderrSubscription;

  /// The stdout subscription or `null` if either
  /// [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String>? _stdoutSubscription;

  new({super.listener, this._process, super.stdioPassthrough});

  /// Force kill the server. Returns exit code future.
  @override
  Future<int> kill({String reason = 'none'}) {
    listener?.killingServerProcess(reason);
    final process = _process!;
    _process = null;
    process.kill();
    return process.exitCode;
  }

  /// Start listening to output from the server,
  /// and deliver notifications to [notificationProcessor].
  @override
  void listenToOutput({NotificationProcessor? notificationProcessor}) {
    _stdoutSubscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) => outputProcessor(line, notificationProcessor));
    _stderrSubscription = _process!.stderr
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) => errorProcessor(line, notificationProcessor));
  }

  /// Send a command to the server. An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges
  /// the command with a response.
  /// If the server acknowledges the command with a normal (non-error) response,
  /// the future will be completed with the 'result' field from the response.
  /// If the server acknowledges the command with an error response,
  /// the future will be completed with an error.
  @override
  Future<Map<String, Object?>?> send(
    String method,
    Map<String, Object?>? params,
  ) => sendCommandWith(method, params, _process!.stdin.add);

  /// Start the server.
  ///
  /// If [profileServer] is `true`, the server will be started
  /// with "--observe" and "--pause-isolates-on-exit", allowing the observatory
  /// to be used.
  ///
  /// If [serverPath] is specified, then that analysis server will be launched
  /// (typically Dart source or a `.dill` kernel file via `dart`, or an AOT
  /// snapshot via `dartaotruntime`); otherwise the analysis server AOT snapshot
  /// in the SDK will be launched with `dartaotruntime`.
  ///
  /// If [enableAsserts] is specified, then asserts will be enabled in the new
  /// dart process for that server. This is typically just useful to enable
  /// locally for debugging.
  ///
  /// When launching an AOT snapshot, [profileServer], [servicePort], and
  /// [enableAsserts] are unsupported and throw an [UnsupportedError].
  @override
  Future start({
    String? clientId,
    String? clientVersion,
    int? diagnosticPort,
    String? instrumentationLogFile,
    bool profileServer = false,
    String? sdkPath,
    String? serverPath,
    int? servicePort,
    bool suppressAnalytics = true,
    bool useAnalysisHighlight2 = false,
    bool enableAsserts = false,
    String? dartBinary,
  }) async {
    if (_process != null) {
      throw Exception('Process already started');
    }

    final resolvedExeDir = dirname(Platform.resolvedExecutable);
    // Look in both the running executable's directory (when invoked from an
    // SDK's `bin/`) and `dart-sdk/bin/` (when invoked from a Dart build root).
    final sdkBinCandidates = [
      resolvedExeDir,
      join(resolvedExeDir, 'dart-sdk', 'bin'),
    ];

    // Whether the server will be launched with `dartaotruntime` instead of
    // `dart`; AOT runtimes reject VM flags such as `--packages`,
    // `--enable-asserts`, and `--observe`.
    final bool isAot;
    final String resolvedServerPath;
    String? preferredBinDir;
    if (serverPath == null) {
      // No custom server entry point was passed: default to the SDK's prebuilt
      // AOT snapshot.
      isAot = true;
      ({String snapshot, String binDir})? found;
      for (final binDir in sdkBinCandidates) {
        final candidateSnapshot = normalize(
          join(binDir, 'snapshots', 'analysis_server_aot.dart.snapshot'),
        );
        if (FileSystemEntity.isFileSync(candidateSnapshot)) {
          found = (snapshot: candidateSnapshot, binDir: binDir);
          break;
        }
      }
      if (found == null) {
        throw StateError(
          'Unable to locate the SDK analysis server AOT snapshot '
          '(analysis_server_aot.dart.snapshot) relative to '
          '${Platform.resolvedExecutable}. Specify serverPath to run from '
          'source.',
        );
      }
      resolvedServerPath = found.snapshot;
      preferredBinDir = found.binDir;
    } else {
      resolvedServerPath = serverPath;
      // A custom [serverPath] was provided. Treat it as AOT if it points to a
      // built AOT snapshot or [dartBinary] is `dartaotruntime`; otherwise
      // assume Dart source or a `.dill` kernel file run with `dart`.
      isAot =
          (dartBinary != null &&
              basenameWithoutExtension(dartBinary) == 'dartaotruntime') ||
          serverPath.endsWith('_aot.dart.snapshot') ||
          serverPath.endsWith('_aot_product.dart.snapshot');
    }

    final resolvedDartBinary = _resolveDartBinary(
      dartBinary: dartBinary,
      isAot: isAot,
      sdkBinCandidates: [?preferredBinDir, ...sdkBinCandidates],
    );

    // `dartaotruntime` (especially product-mode SDK builds) does not support
    // JIT/VM-service flags.
    if (isAot && (profileServer || servicePort != null || enableAsserts)) {
      throw UnsupportedError(
        'VM flags (profileServer, servicePort, enableAsserts) are not '
        'supported when running an analysis server AOT snapshot; '
        'specify serverPath to run from source.',
      );
    }

    var arguments = <String>[];
    if (!isAot) {
      // Only pass VM flags when running on `dart` (source or kernel); passing
      // flags like `--packages` to `dartaotruntime` fails with unrecognized
      // flag errors.
      if (profileServer) {
        if (servicePort == null) {
          arguments.add('--observe');
        } else {
          arguments.add('--observe=$servicePort');
        }
        arguments.add('--pause-isolates-on-exit');
      } else if (servicePort != null) {
        arguments.add('--enable-vm-service=$servicePort');
      }
      if (Platform.packageConfig != null) {
        arguments.add('--packages=${Platform.packageConfig}');
      }
      if (enableAsserts) {
        arguments.add('--enable-asserts');
      }
    }
    //
    // Add the server executable.
    //
    arguments.add(resolvedServerPath);

    arguments.addAll(
      getServerArguments(
        clientId: clientId,
        clientVersion: clientVersion,
        suppressAnalytics: suppressAnalytics,
        diagnosticPort: diagnosticPort,
        instrumentationLogFile: instrumentationLogFile,
        sdkPath: sdkPath,
        useAnalysisHighlight2: useAnalysisHighlight2,
      ),
    );

    listener?.startingServer(resolvedDartBinary, arguments);
    final process = await Process.start(resolvedDartBinary, arguments);
    _process = process;
    // ignore: unawaited_futures
    process.exitCode.then((int code) {
      if (code != 0 && _process != null) {
        // Report an error if server abruptly terminated
        listener?.unexpectedStop(code);
      }
    });
  }

  /// Attempt to gracefully shutdown the server.
  /// If that fails, then kill the process.
  @override
  Future<int> stop({Duration? timeLimit}) async {
    timeLimit ??= const Duration(seconds: 5);

    final process = _process;
    if (process == null) {
      // Process already exited
      return -1;
    }

    final future = send(serverRequestShutdown, null);
    _process = null;
    await future
        // fall through to wait for exit
        .timeout(
          timeLimit,
          onTimeout: () {
            return {};
          },
        )
        .whenComplete(() async {
          await _stderrSubscription?.cancel();
          _stderrSubscription = null;
          await _stdoutSubscription?.cancel();
          _stdoutSubscription = null;
        });
    return process.exitCode.timeout(
      timeLimit,
      onTimeout: () {
        listener?.killingServerProcess('server failed to exit');
        process.kill();
        return process.exitCode;
      },
    );
  }

  /// Resolves the executable (`dartaotruntime` or `dart`) used to launch the
  /// analysis server.
  static String _resolveDartBinary({
    required String? dartBinary,
    required bool isAot,
    required List<String> sdkBinCandidates,
  }) {
    if (dartBinary != null) return dartBinary;
    if (!isAot) return Platform.executable;

    final aotRuntimeName = Platform.isWindows
        ? 'dartaotruntime.exe'
        : 'dartaotruntime';
    return sdkBinCandidates
        .map((binDir) => normalize(join(binDir, aotRuntimeName)))
        .firstWhere(FileSystemEntity.isFileSync, orElse: () => aotRuntimeName);
  }
}
