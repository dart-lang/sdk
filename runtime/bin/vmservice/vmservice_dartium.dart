// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_dartium;

import 'dart:isolate';
import 'vmservice.dart';

// The receive port that isolate startup / shutdown messages are delivered on.
RawReceivePort _receivePort;
// The receive port that service request messages are delivered on.
RawReceivePort _requestPort;

// The native method that is called to post the response back to DevTools.
void postResponse(String response, int cookie) native "VMService_PostResponse";

/// Dartium recieves messages through the _requestPort and posts
/// responses via postResponse. It has a single persistent client.
class DartiumClient extends Client {
  DartiumClient(port, service) : super(service) {
    port.handler = ((message) {
      if (message == null) {
        return;
      }
      if (message is! List) {
        return;
      }
      if (message.length != 2) {
        return;
      }
      if (message[0] is! String) {
        return;
      }
      var uri = Uri.parse(message[0]);
      var cookie = message[1];
      onMessage(cookie, new Message.fromUri(uri));
    });
  }

  void post(var seq, String response) {
    postResponse(response, seq);
  }

  dynamic toJson() {
    var map = super.toJson();
    map['type'] = 'DartiumClient';
  }
}


main() {
  // Create VmService.
  var service = new VMService();
  _receivePort = service.receivePort;
  _requestPort = new RawReceivePort();
  new DartiumClient(_requestPort, service);
}
