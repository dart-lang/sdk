// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/listener/server_listener.dart';
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
  Process _process;

  /// The stderr subscription or `null` if either
  /// [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String> _stderrSubscription;

  /// The stdout subscription or `null` if either
  /// [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String> _stdoutSubscription;

  Server(
      {ServerListener listener, Process process, bool stdioPassthrough = false})
      : _process = process,
        super(listener: listener, stdioPassthrough: stdioPassthrough);

  /// Force kill the server. Returns exit code future.
  @override
  Future<int> kill({String reason = 'none'}) {
    listener?.killingServerProcess(reason);
    final process = _process;
    _process = null;
    process.kill();
    return process.exitCode;
  }

  /// Start listening to output from the server,
  /// and deliver notifications to [notificationProcessor].
  @override
  void listenToOutput({NotificationProcessor notificationProcessor}) {
    _stdoutSubscription = _process.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((line) => outputProcessor(line, notificationProcessor));
    _stderrSubscription = _process.stderr
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
  Future<Map<String, dynamic>> send(
          String method, Map<String, dynamic> params) =>
      sendCommandWith(method, params, _process.stdin.add);

  /// Start the server.
  ///
  /// If [profileServer] is `true`, the server will be started
  /// with "--observe" and "--pause-isolates-on-exit", allowing the observatory
  /// to be used.
  ///
  /// If [serverPath] is specified, then that analysis server will be launched,
  /// otherwise the analysis server snapshot in the SDK will be launched.
  ///
  /// If [enableAsserts] is specified, then asserts will be enabled in the new
  /// dart process for that server. This is typically just useful to enable
  /// locally for debugging.
  @override
  Future start({
    String clientId,
    String clientVersion,
    int diagnosticPort,
    String instrumentationLogFile,
    bool profileServer = false,
    String sdkPath,
    String serverPath,
    int servicesPort,
    bool suppressAnalytics = true,
    bool useAnalysisHighlight2 = false,
    bool enableAsserts = false,
  }) async {
    if (_process != null) {
      throw Exception('Process already started');
    }
    var dartBinary = Platform.executable;

    // The integration tests run 3x faster when run from snapshots
    // (you need to run test.py with --use-sdk).
    if (serverPath == null) {
      // Look for snapshots/analysis_server.dart.snapshot.
      serverPath = normalize(join(dirname(Platform.resolvedExecutable),
          'snapshots', 'analysis_server.dart.snapshot'));

      if (!FileSystemEntity.isFileSync(serverPath)) {
        // Look for dart-sdk/bin/snapshots/analysis_server.dart.snapshot.
        serverPath = normalize(join(dirname(Platform.resolvedExecutable),
            'dart-sdk', 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
      }
    }

    var arguments = <String>[];
    //
    // Add VM arguments.
    //
    if (profileServer) {
      if (servicesPort == null) {
        arguments.add('--observe');
      } else {
        arguments.add('--observe=$servicesPort');
      }
      arguments.add('--pause-isolates-on-exit');
    } else if (servicesPort != null) {
      arguments.add('--enable-vm-service=$servicesPort');
    }
    if (Platform.packageConfig != null) {
      arguments.add('--packages=${Platform.packageConfig}');
    }
    if (enableAsserts) {
      arguments.add('--enable-asserts');
    }
    //
    // Add the server executable.
    //
    arguments.add(serverPath);

    arguments.addAll(getServerArguments(
        clientId: clientId,
        clientVersion: clientVersion,
        suppressAnalytics: suppressAnalytics,
        diagnosticPort: diagnosticPort,
        instrumentationLogFile: instrumentationLogFile,
        sdkPath: sdkPath,
        useAnalysisHighlight2: useAnalysisHighlight2));

    listener?.startingServer(dartBinary, arguments);
    _process = await Process.start(dartBinary, arguments);
    // ignore: unawaited_futures
    _process.exitCode.then((int code) {
      if (code != 0 && _process != null) {
        // Report an error if server abruptly terminated
        listener?.unexpectedStop(code);
      }
    });
  }

  /// Attempt to gracefully shutdown the server.
  /// If that fails, then kill the process.
  @override
  Future<int> stop({Duration timeLimit}) async {
    timeLimit ??= const Duration(seconds: 5);
    if (_process == null) {
      // Process already exited
      return -1;
    }
    final future = send(SERVER_REQUEST_SHUTDOWN, null);
    final process = _process;
    _process = null;
    await future
        // fall through to wait for exit
        .timeout(timeLimit, onTimeout: () {
      return null;
    }).whenComplete(() async {
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
}
