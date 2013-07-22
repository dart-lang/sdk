// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

class RunningIsolate implements ServiceRequestRouter {
  final SendPort sendPort;
  String id = 'Unknown';

  RunningIsolate(this.sendPort);

  Future sendMessage(String request) {
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

  bool route(ServiceRequest request) {
    // Do nothing for now.
    return false;
  }

  void sendIdRequest() {
    var request = JSON.stringify({'p': ['id'], 'k': [], 'v': []});
    sendMessage(request).then(_handleIdResponse);
  }

  void _handleIdResponse(responseString) {
    var response;
    try {
      response = JSON.parse(responseString);
    } catch (e) {
      id = 'Error retrieving isolate id.';
      return;
    }
    id = response['id'];
  }
}
