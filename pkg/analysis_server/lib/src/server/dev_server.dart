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
  DevChannel _channel;

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
      Map<String, dynamic> params = notification.params;
      if (params.containsKey('analysis')) {
        bool isAnalyzing = params['analysis']['isAnalyzing'];
        if (!isAnalyzing) {
          timer.stop();
          var seconds = timer.elapsedMilliseconds / 1000.0;
          print('Completed in ${seconds.toStringAsFixed(1)}s.');
          whenComplete.complete(exitCode);
        }
      }
    }

    void handleErrorsNotification(Notification notification) {
      String filePath = notification.params['file'];
      List<Map> errors = notification.params['errors'];

      if (errors.isEmpty) {
        return;
      }

      filePath = path.relative(filePath);

      for (var error in errors) {
        if (error['type'] == 'TODO') {
          continue;
        }

        String severity = error['severity'].toLowerCase();
        if (severity == 'warning' && exitCode < 1) {
          exitCode = 1;
        } else if (severity == 'error' && exitCode < 2) {
          exitCode = 2;
        }

        String message = error['message'];
        if (message.endsWith('.')) {
          message = message.substring(0, message.length - 1);
        }
        String code = error['code'];
        int line = error['location']['startLine'];
        int column = error['location']['startColumn'];

        print('  $severity • $bold$message$none at $filePath:$line:$column • '
            '($code)');
      }
    }

    void handleServerError(Notification notification) {
      Map<String, dynamic> params = notification.params;
      String message = params['message'];
      String stackTrace = params['stackTrace'];

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
  void close() {
    _notificationController.close();
  }

  @override
  void listen(
    void Function(Request request) onRequest, {
    Function onError,
    void Function() onDone,
  }) {
    _requestController.stream.listen(
      onRequest,
      onError: onError,
      onDone: onDone,
    );
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
