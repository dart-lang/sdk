// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:path/path.dart' as path;

/// Instances of the class [DevAnalysisServer] implement a simple analysis
/// server implementation, used to analyze one or more packages and then
/// terminate the server.
class DevAnalysisServer {
  static bool get _terminalSupportsAnsi {
    return stdout.supportsAnsiEscapes &&
        stdioType(stdout) == StdioType.terminal;
  }

  /// An object that can handle either a WebSocket connection or a connection
  /// to the client over stdio.
  final SocketServer socketServer;

  int _nextId = 0;
  late DevChannel _channel;

  /// Initialize a newly created stdio server.
  DevAnalysisServer(this.socketServer);

  void initServer() {
    _channel = DevChannel();
    socketServer.createAnalysisServer(_channel);
  }

  /// Analyze the given directories and display any results to stdout.
  ///
  /// Return a future that will be completed with an exit code when analysis
  /// finishes.
  Future<int> processDirectories(List<String> directories) async {
    var bold = _terminalSupportsAnsi ? '\u001b[1m' : '';
    var none = _terminalSupportsAnsi ? '\u001b[0m' : '';

    print('Analyzing ${directories.join(', ')}...');

    var timer = Stopwatch()..start();

    var whenComplete = Completer<int>();

    var exitCode = 0;

    void handleStatusNotification(Notification notification) {
      var params = notification.params;
      if (params != null && params.containsKey('analysis')) {
        var isAnalyzing =
            (params['analysis'] as Map<String, Object>)['isAnalyzing'] as bool;
        if (!isAnalyzing) {
          timer.stop();
          var seconds = timer.elapsedMilliseconds / 1000.0;
          print('Completed in ${seconds.toStringAsFixed(1)}s.');
          whenComplete.complete(exitCode);
        }
      }
    }

    void handleErrorsNotification(Notification notification) {
      var params = notification.params!;
      var filePath = params['file'] as String;
      var errors = params['errors'] as List<Map>;

      if (errors.isEmpty) {
        return;
      }

      filePath = path.relative(filePath);

      for (var error in errors) {
        if (error['type'] == 'TODO') {
          continue;
        }

        var severity = (error['severity'] as String).toLowerCase();
        if (severity == 'warning' && exitCode < 1) {
          exitCode = 1;
        } else if (severity == 'error' && exitCode < 2) {
          exitCode = 2;
        }

        var message = error['message'] as String;
        if (message.endsWith('.')) {
          message = message.substring(0, message.length - 1);
        }
        var code = error['code'] as String;
        var location = error['location'] as Map<Object?, Object?>;
        var line = location['startLine'] as int;
        var column = location['startColumn'] as int;

        print('  $severity • $bold$message$none at $filePath:$line:$column • '
            '($code)');
      }
    }

    void handleServerError(Notification notification) {
      var params = notification.params!;
      var message = params['message'] as String;
      var stackTrace = params['stackTrace'] as String?;

      print(message);
      if (stackTrace != null) {
        print(stackTrace);
      }

      exitCode = 3;

      // Ensure we terminate training if we get an exception from the analysis
      // server.
      whenComplete.completeError(message);
    }

    var notificationSubscriptions =
        _channel.onNotification.listen((Notification notification) {
      if (notification.event == 'server.status') {
        handleStatusNotification(notification);
      } else if (notification.event == 'analysis.errors') {
        handleErrorsNotification(notification);
      } else if (notification.event == 'server.error') {
        handleServerError(notification);
      }
    });

    _channel.sendRequest(Request('${_nextId++}', 'server.setSubscriptions', {
      'subscriptions': ['STATUS'],
    }));

    directories =
        directories.map((dir) => path.normalize(path.absolute(dir))).toList();

    _channel.sendRequest(Request(
      '${_nextId++}',
      'analysis.setAnalysisRoots',
      {'included': directories, 'excluded': []},
    ));

    return whenComplete.future.whenComplete(() {
      notificationSubscriptions.cancel();

      _channel.sendRequest(Request(
        '${_nextId++}',
        'analysis.setAnalysisRoots',
        {'included': [], 'excluded': []},
      ));
    });
  }
}

class DevChannel implements ServerCommunicationChannel {
  final StreamController<Request> _requestController =
      StreamController.broadcast();

  final StreamController<Notification> _notificationController =
      StreamController.broadcast();

  final Map<String, Completer<Response>> _responseCompleters = {};

  Stream<Notification> get onNotification => _notificationController.stream;

  @override
  Stream<Request> get requests => _requestController.stream;

  @override
  void close() {
    _notificationController.close();
  }

  @override
  void sendNotification(Notification notification) {
    _notificationController.add(notification);
  }

  Future<Response> sendRequest(Request request) {
    var completer = Completer<Response>();
    _responseCompleters[request.id] = completer;
    _requestController.add(request);
    return completer.future;
  }

  @override
  void sendResponse(Response response) {
    var completer = _responseCompleters.remove(response.id);
    completer?.complete(response);
  }
}
