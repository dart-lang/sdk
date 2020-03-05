// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:path/path.dart';

/// Type of callbacks used to process notifications.
typedef NotificationProcessor = void Function(Notification notification);

/// Instances of the class [Server] manage a server process,
/// and facilitate communication to and from the server.
///
/// Clients may not extend, implement or mix-in this class.
class Server {
  /// If not `null`, [_listener] will be sent information
  /// about interactions with the server.
  final ServerListener _listener;

  /// Server process object, or `null` if server hasn't been started yet
  /// or if the server has already been stopped.
  Process _process;

  /// Commands that have been sent to the server but not yet acknowledged,
  /// and the [Completer] objects which should be completed
  /// when acknowledgement is received.
  final _pendingCommands = <String, Completer<Map<String, dynamic>>>{};

  /// Number which should be used to compute the 'id'
  /// to send in the next command sent to the server.
  int _nextId = 0;

  /// The stderr subscription or `null` if either
  /// [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String> _stderrSubscription;

  /// The stdout subscription or `null` if either
  /// [listenToOutput] has not been called or [stop] has been called.
  StreamSubscription<String> _stdoutSubscription;

  Server({ServerListener listener, Process process})
      : _listener = listener,
        _process = process;

  /// Force kill the server. Returns exit code future.
  Future<int> kill({String reason = 'none'}) {
    _listener?.killingServerProcess(reason);
    final process = _process;
    _process = null;
    process.kill();
    return process.exitCode;
  }

  /// Start listening to output from the server,
  /// and deliver notifications to [notificationProcessor].
  void listenToOutput({NotificationProcessor notificationProcessor}) {
    _stdoutSubscription = _process.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((String line) {
      String trimmedLine = line.trim();

      // Guard against lines like:
      //   {"event":"server.connected","params":{...}}Observatory listening on ...
      const observatoryMessage = 'Observatory listening on ';
      if (trimmedLine.contains(observatoryMessage)) {
        trimmedLine = trimmedLine
            .substring(0, trimmedLine.indexOf(observatoryMessage))
            .trim();
      }
      if (trimmedLine.isEmpty) {
        return;
      }

      _listener?.messageReceived(trimmedLine);
      Map<String, dynamic> message;
      try {
        message = json.decoder.convert(trimmedLine);
      } catch (exception) {
        _listener?.badMessage(trimmedLine, exception);
        return;
      }

      final id = message[Response.ID];
      if (id != null) {
        // Handle response
        final completer = _pendingCommands.remove(id);
        if (completer == null) {
          _listener?.unexpectedResponse(message, id);
        }
        if (message.containsKey(Response.ERROR)) {
          completer.completeError(RequestError.fromJson(
              ResponseDecoder(null), '.error', message[Response.ERROR]));
        } else {
          completer.complete(message[Response.RESULT]);
        }
      } else {
        // Handle notification
        final String event = message[Notification.EVENT];
        if (event != null) {
          if (notificationProcessor != null) {
            notificationProcessor(
                Notification(event, message[Notification.PARAMS]));
          }
        } else {
          _listener?.unexpectedMessage(message);
        }
      }
    });
    _stderrSubscription = _process.stderr
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((String line) {
      String trimmedLine = line.trim();
      _listener?.errorMessage(trimmedLine);
    });
  }

  /// Send a command to the server. An 'id' will be automatically assigned.
  /// The returned [Future] will be completed when the server acknowledges
  /// the command with a response.
  /// If the server acknowledges the command with a normal (non-error) response,
  /// the future will be completed with the 'result' field from the response.
  /// If the server acknowledges the command with an error response,
  /// the future will be completed with an error.
  Future<Map<String, dynamic>> send(
      String method, Map<String, dynamic> params) {
    String id = '${_nextId++}';
    Map<String, dynamic> command = <String, dynamic>{
      Request.ID: id,
      Request.METHOD: method
    };
    if (params != null) {
      command[Request.PARAMS] = params;
    }
    final completer = Completer<Map<String, dynamic>>();
    _pendingCommands[id] = completer;
    String line = json.encode(command);
    _listener?.requestSent(line);
    _process.stdin.add(utf8.encoder.convert('$line\n'));
    return completer.future;
  }

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
    String dartBinary = Platform.executable;

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

    List<String> arguments = [];
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
    //
    // Add server arguments.
    //
    // TODO(danrubel): Consider moving all cmdline argument consts
    // out of analysis_server and into analysis_server_client
    if (clientId != null) {
      arguments.add('--client-id');
      arguments.add(clientId);
    }
    if (clientVersion != null) {
      arguments.add('--client-version');
      arguments.add(clientVersion);
    }
    if (suppressAnalytics) {
      arguments.add('--suppress-analytics');
    }
    if (diagnosticPort != null) {
      arguments.add('--port');
      arguments.add(diagnosticPort.toString());
    }
    if (instrumentationLogFile != null) {
      arguments.add('--instrumentation-log-file=$instrumentationLogFile');
    }
    if (sdkPath != null) {
      arguments.add('--sdk=$sdkPath');
    }
    if (useAnalysisHighlight2) {
      arguments.add('--useAnalysisHighlight2');
    }
    _listener?.startingServer(dartBinary, arguments);
    _process = await Process.start(dartBinary, arguments);
    // ignore: unawaited_futures
    _process.exitCode.then((int code) {
      if (code != 0 && _process != null) {
        // Report an error if server abruptly terminated
        _listener?.unexpectedStop(code);
      }
    });
  }

  /// Attempt to gracefully shutdown the server.
  /// If that fails, then kill the process.
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
        _listener?.killingServerProcess('server failed to exit');
        process.kill();
        return process.exitCode;
      },
    );
  }
}
