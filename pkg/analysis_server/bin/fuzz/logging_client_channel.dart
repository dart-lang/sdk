// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of server.manager;

/**
 * A client channel that logs communication to stdout
 * and handles errors received from the server.
 */
class LoggingClientChannel implements ClientCommunicationChannel {
  final ClientCommunicationChannel channel;
  int serverErrorCount = 0;

  LoggingClientChannel(this.channel) {
    channel.notificationStream.listen((Notification notification) {
      _logNotification(notification);
      if (notification.event == 'server.error') {
        ServerErrorParams error =
            new ServerErrorParams.fromNotification(notification);
        _handleError(
            'Server reported error: ${error.message}',
            error.stackTrace);
      }
    });
  }

  @override
  Stream<Notification> get notificationStream => channel.notificationStream;

  @override
  void set notificationStream(Stream<Notification> _notificationStream) {
    throw 'invalid operation';
  }

  @override
  Stream<Response> get responseStream => channel.responseStream;

  @override
  void set responseStream(Stream<Response> _responseStream) {
    throw 'invalid operation';
  }

  @override
  Future close() {
    print('Requesting client channel be closed');
    return channel.close().then((_) {
      print('Client channel closed');
    });
  }

  @override
  Future<Response> sendRequest(Request request) {
    _logOperation('=>', request);
    return channel.sendRequest(request).then((Response response) {
      RequestError error = response.error;
      if (error != null) {
        error.code;
        stderr.write('Server Error ${error.code}: ${error.message}');
        print(error.stackTrace);
        exitCode = 31;
      }
      _logOperation('<=', request);
      return response;
    });
  }

  void _handleError(String errMsg, String stackTrace) {
    //error.isFatal;
    stderr.writeln('>>> Server reported exception');
    stderr.writeln(errMsg);
    print(stackTrace);
    serverErrorCount++;
  }

  void _logNotification(Notification notification) {
    print('<=       ${notification.event}');
  }

  void _logOperation(String direction, Request request) {
    String id = request.id.padLeft(5);
    String method = request.method.padRight(20);
    print('$direction $id $method');
  }
}
