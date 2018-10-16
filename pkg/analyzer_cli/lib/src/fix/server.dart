// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:path/path.dart';

/**
 * Type of callbacks used to process notifications.
 */
typedef void NotificationProcessor(String event, params);

/**
 * Instances of the class [Server] manage a connection to a server process, and
 * facilitate communication to and from the server.
 */
class Server {
  /**
   * Server process object, or null if server hasn't been started yet.
   */
  Process _process;

  /**
   * Commands that have been sent to the server but not yet acknowledged, and
   * the [Completer] objects which should be completed when acknowledgement is
   * received.
   */
  final Map<String, Completer<Map<String, dynamic>>> _pendingCommands =
      <String, Completer<Map<String, dynamic>>>{};

  /**
   * Number which should be used to compute the 'id' to send in the next command
   * sent to the server.
   */
  int _nextId = 0;

  /**
   * Messages which have been exchanged with the server; we buffer these
   * up until the test finishes, so that they can be examined in the debugger
   * or printed out in response to a call to [debugStdio].
   */
  final List<String> _recordedStdio = <String>[];

  /**
   * True if we are currently printing out messages exchanged with the server.
   */
  bool _debuggingStdio = false;

  /**
   * True if we've received bad data from the server, and we are aborting the
   * test.
   */
  bool _receivedBadDataFromServer = false;

  /**
   * Stopwatch that we use to generate timing information for debug output.
   */
  Stopwatch _time = new Stopwatch();

  /**
   * The [currentElapseTime] at which the last communication was received from the server
   * or `null` if no communication has been received.
   */
  double lastCommunicationTime;

  /**
   * The current elapse time (seconds) since the server was started.
   */
  double get currentElapseTime => _time.elapsedTicks / _time.frequency;

  /**
   * Future that completes when the server process exits.
   */
  Future<int> get exitCode => _process.exitCode;

  final Logger logger;

  Server(this.logger);

  /**
   * Print out any messages exchanged with the server.  If some messages have
   * already been exchanged with the server, they are printed out immediately.
   */
  void debugStdio() {
    if (_debuggingStdio) {
      return;
    }
    _debuggingStdio = true;
    for (String line in _recordedStdio) {
      logger.trace(line);
    }
  }

  /**
   * Find the root directory of the analysis_server package by proceeding
   * upward to the 'test' dir, and then going up one more directory.
   */
  String findRoot(String pathname) {
    while (true) {
      String parent = dirname(pathname);
      if (parent.length >= pathname.length) {
        throw new Exception("Can't find root directory");
      }
      String name = basename(pathname);
      if (['benchmark', 'test'].contains(name)) {
        return parent;
      }
      if (name == 'pkg') {
        return join(pathname, 'analysis_server');
      }
      pathname = parent;
    }
  }

  /**
   * Return a future that will complete when all commands that have been sent
   * to the server so far have been flushed to the OS buffer.
   */
  Future flushCommands() {
    return _process.stdin.flush();
  }

  /**
   * Stop the server.
   */
  Future<int> kill(String reason) {
    debugStdio();
    _recordStdio('FORCIBLY TERMINATING PROCESS: $reason');
    _process.kill();
    return _process.exitCode;
  }

  /**
   * Start listening to output from the server, and deliver notifications to
   * [notificationProcessor].
   */
  void listenToOutput(NotificationProcessor notificationProcessor) {
    _process.stdout
        .transform(utf8.decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      lastCommunicationTime = currentElapseTime;
      String trimmedLine = line.trim();

      // Guard against lines like:
      //   {"event":"server.connected","params":{...}}Observatory listening on ...
      final String observatoryMessage = 'Observatory listening on ';
      if (trimmedLine.contains(observatoryMessage)) {
        trimmedLine = trimmedLine
            .substring(0, trimmedLine.indexOf(observatoryMessage))
            .trim();
      }
      if (trimmedLine.isEmpty) {
        return;
      }

      _recordStdio('<== $trimmedLine');
      var message;
      try {
        message = json.decoder.convert(trimmedLine);
      } catch (exception) {
        _badDataFromServer('JSON decode failure: $exception');
        return;
      }
      Map messageAsMap = message;
      if (messageAsMap.containsKey('id')) {
        String id = message['id'];
        Completer<Map<String, dynamic>> completer = _pendingCommands[id];
        if (completer == null) {
          throw 'Unexpected response from server: id=$id';
        } else {
          _pendingCommands.remove(id);
        }
        if (messageAsMap.containsKey('error')) {
          completer.completeError(new ServerErrorMessage(messageAsMap));
        } else {
          Map<String, dynamic> result = messageAsMap['result'];
          completer.complete(result);
        }
      } else {
        String event = messageAsMap['event'];
        notificationProcessor(event, messageAsMap['params']);
      }
    });
    _process.stderr
        .transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter())
        .listen((String line) {
      String trimmedLine = line.trim();
      _recordStdio('ERR:  $trimmedLine');
      _badDataFromServer('Message received on stderr', silent: true);
    });
  }

  /**
   * Send a command to the server.  An 'id' will be automatically assigned.
   * The returned [Future] will be completed when the server acknowledges the
   * command with a response.  If the server acknowledges the command with a
   * normal (non-error) response, the future will be completed with the 'result'
   * field from the response.  If the server acknowledges the command with an
   * error response, the future will be completed with an error.
   */
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
    Completer<Map<String, dynamic>> completer =
        new Completer<Map<String, dynamic>>();
    _pendingCommands[id] = completer;
    String line = json.encode(command);
    _recordStdio('==> $line');
    _process.stdin.add(utf8.encoder.convert("$line\n"));
    return completer.future;
  }

  /**
   * Start the server. If [profileServer] is `true`, the server will be started
   * with "--observe" and "--pause-isolates-on-exit", allowing the observatory
   * to be used.
   */
  Future start({
    int diagnosticPort,
    String instrumentationLogFile,
    bool profileServer: false,
    String sdkPath,
    int servicesPort,
    bool useAnalysisHighlight2: false,
    bool useSnapshot: true,
  }) async {
    if (_process != null) {
      throw new Exception('Process already started');
    }
    _time.start();
    String dartBinary = Platform.executable;

    String serverPath;

    // The integration tests run 3x faster when run from snapshots (you need to
    // run test.py with --use-sdk).
    if (useSnapshot) {
      // Look for snapshots/analysis_server.dart.snapshot.
      serverPath = normalize(join(dirname(Platform.resolvedExecutable),
          'snapshots', 'analysis_server.dart.snapshot'));

      if (!FileSystemEntity.isFileSync(serverPath)) {
        // Look for dart-sdk/bin/snapshots/analysis_server.dart.snapshot.
        serverPath = normalize(join(dirname(Platform.resolvedExecutable),
            'dart-sdk', 'bin', 'snapshots', 'analysis_server.dart.snapshot'));
      }
    } else {
      String rootDir =
          findRoot(Platform.script.toFilePath(windows: Platform.isWindows));
      serverPath = normalize(join(rootDir, 'bin', 'server.dart'));
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
    arguments.add('--suppress-analytics');
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
    _process = await Process.start(dartBinary, arguments);
    _process.exitCode.then((int code) {
      if (code != 0) {
        _badDataFromServer('server terminated with exit code $code');
      }
    });
  }

  /**
   * Deal with bad data received from the server.
   */
  void _badDataFromServer(String details, {bool silent: false}) {
    if (!silent) {
      _recordStdio('BAD DATA FROM SERVER: $details');
    }
    if (_receivedBadDataFromServer) {
      // We're already dealing with it.
      return;
    }
    _receivedBadDataFromServer = true;
    debugStdio();
    // Give the server 1 second to continue outputting bad data
    // such as outputting a stacktrace.
    new Future.delayed(new Duration(seconds: 1), () {
      throw 'Bad data received from server: $details';
    });
  }

  /**
   * Record a message that was exchanged with the server, and print it out if
   * [debugStdio] has been called.
   */
  void _recordStdio(String line) {
    double elapsedTime = currentElapseTime;
    line = "$elapsedTime: $line";
    if (_debuggingStdio) {
      logger.trace(line);
    }
    _recordedStdio.add(line);
  }
}

/**
 * An error result from a server request.
 */
class ServerErrorMessage {
  final Map message;

  ServerErrorMessage(this.message);

  dynamic get error => message['error'];

  String toString() => message.toString();
}
