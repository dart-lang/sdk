// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class RunningIsolate implements ServiceRequestRouter {
  final SendPort sendPort;
  String name = 'Unknown';

  RunningIsolate(this.sendPort);

  Future sendMessage(List request) {
    final completer = new Completer.sync();
    final receivePort = new ReceivePort();
    sendServiceMessage(sendPort, receivePort, request);
    receivePort.receive((value, ignoreReplyTo) {
      receivePort.close();
      if (value is Exception) {
        completer.completeError(value);
      } else {
        completer.complete(value);
      }
    });
    return completer.future;
  }

  Future route(ServiceRequest request) {
    // Send message to isolate.
    var message = request.toServiceCallMessage();
    return sendMessage(message).then((response) {
      request.setResponse(response);
      return new Future.value(request);
    });
  }

  void _sendNameRequest() {
    var request = new ServiceRequest();
    request.parse(Uri.parse('/name'));
    sendMessage(request.toServiceCallMessage()).then(_handleNameResponse);
  }

  void _handleNameResponse(String responseString) {
    try {
      var response = JSON.parse(responseString);
      name = response['name'];
    } catch (e) {
      name = 'Error retrieving isolate name.';
      return;
    }
    if (name == null) {
      name = 'Error retrieving isolate name.';
    }
  }
}
