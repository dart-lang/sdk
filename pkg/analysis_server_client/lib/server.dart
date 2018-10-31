// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';

/// Type of callbacks used to process notifications.
typedef void NotificationProcessor(String event, Map<String, dynamic> params);

/// Instances of the class [Server] manage a connection to a server process,
/// and facilitate communication to and from the server.
class Server {
  /// Server process object, or `null` if server hasn't been started yet.
  Process _process;

  /// Commands that have been sent to the server but not yet acknowledged,
  /// and the [Completer] objects which should be completed
  /// when acknowledgement is received.
  final _pendingCommands = <String, Completer<Map<String, dynamic>>>{};

  /// Number which should be used to compute the 'id'
  /// to send in the next command sent to the server.
  int _nextId = 0;

  /// True if we've received bad data from the server.
  bool _receivedBadDataFromServer = false;

  /// Stopwatch that we use to generate timing information for debug output.
  Stopwatch _time = new Stopwatch();

  /// The [currentElapseTime] at which the last communication was received from
  /// the server or `null` if no communication has been received.
  double lastCommunicationTime;

  Server([Process process]) : this._process = process;

  /// The current elapse time (seconds) since the server was started.
  double get currentElapseTime => _time.elapsedTicks / _time.frequency;

  /// Future that completes when the server process exits.
  Future<int> get exitCode => _process.exitCode;

  /// Return a future that will complete when all commands that have been sent
  /// to the server so far have been flushed to the OS buffer.
  Future<void> flushCommands() => _process.stdin.flush();

  /// Force kill the server. Returns exit code future.
  Future<int> kill([String reason = 'none']) {
    logMessage('FORCIBLY TERMINATING PROCESS: ', reason);
    _process.kill();
    return _process.exitCode;
  }

  /// Start listening to output from the server,
  /// and deliver notifications to [notificationProcessor].
  void listenToOutput({NotificationProcessor notificationProcessor}) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      lastCommunicationTime = currentElapseTime;
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

      logMessage('<== ', trimmedLine);
      Map<String, dynamic> message;
      try {
        message = json.decoder.convert(trimmedLine);
      } catch (exception) {
        logBadDataFromServer('JSON decode failure: $exception');
        return;
      }

      final id = message['id'];
      if (id != null) {
        // Handle response
        final completer = _pendingCommands.remove(id);
        if (completer == null) {
          throw 'Unexpected response from server: id=$id';
        }
        if (message.containsKey('error')) {
          completer.completeError(new ServerErrorMessage(message));
        } else {
          completer.complete(message['result']);
        }
      } else {
        // Handle notification
        final String event = message['event'];
        if (event != null) {
          if (notificationProcessor != null) {
            notificationProcessor(event, message['params']);
          }
        } else {
          logBadDataFromServer('Unexpected message from server');
        }
      }
    });

    _process.stderr
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      String trimmedLine = line.trim();
      logMessage('ERR: ', trimmedLine);
      logBadDataFromServer('Message received on stderr', silent: true);
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
      'id': id,
      'method': method
    };
    if (params != null) {
      command['params'] = params;
    }
    final completer = new Completer<Map<String, dynamic>>();
    _pendingCommands[id] = completer;
    String line = json.encode(command);
    logMessage('==> ', line);
    _process.stdin.add(utf8.encoder.convert("$line\n"));
    return completer.future;
  }

  /**
   * Start the server.
   *
   * If [profileServer] is `true`, the server will be started
   * with "--observe" and "--pause-isolates-on-exit", allowing the observatory
   * to be used.
   *
   * If [serverPath] is specified, then that analysis server will be launched,
   * otherwise the analysis server snapshot in the SDK will be launched.
   */
  Future start({
    String clientId,
    String clientVersion,
    int diagnosticPort,
    String instrumentationLogFile,
    bool profileServer: false,
    String sdkPath,
    String serverPath,
    int servicesPort,
    bool suppressAnalytics: true,
    bool useAnalysisHighlight2: false,
  }) async {
    if (_process != null) {
      throw new Exception('Process already started');
    }
    _time.start();
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
    logMessage(
        'Starting analysis server: ', '$dartBinary ${arguments.join(' ')}');
    _process = await Process.start(dartBinary, arguments);
    _process.exitCode.then((int code) {
      if (code != 0) {
        logBadDataFromServer('server terminated with exit code $code');
      }
    });
  }

  /// Deal with bad data received from the server.
  void logBadDataFromServer(String details, {bool silent: false}) {
    if (!silent) {
      logMessage('BAD DATA FROM SERVER: ', details);
    }
    if (_receivedBadDataFromServer) {
      // We're already dealing with it.
      return;
    }
    _receivedBadDataFromServer = true;
    // Give the server 1 second to continue outputting bad data
    // such as outputting a stacktrace.
    new Future.delayed(new Duration(seconds: 1), () {
      throw 'Bad data received from server: $details';
    });
  }

  /// Log a message that was exchanged with the server.
  /// Subclasses may override as needed.
  void logMessage(String prefix, String details) {
    // no-op
  }
}

/// An error result from a server request.
class ServerErrorMessage {
  final Map<String, dynamic> message;

  ServerErrorMessage(this.message);

  Map<String, dynamic> get error => message['error'];
  get errorCode => error['code'];
  get errorMessage => error['message'];
  get stackTrace => error['stackTrace'];

  String toString() => message.toString();
}
