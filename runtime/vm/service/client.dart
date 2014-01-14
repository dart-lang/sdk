// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of vmservice;

// A service client.
abstract class Client {
  /// Port that lives as long as the network client.
  final RawReceivePort receivePort = new RawReceivePort();
  final VMService service;

  Client(this.service) {
    receivePort.handler = (response) {
      post(null, response);
    };
    service._addClient(this);
  }

  /// When implementing, call [close] when the network connection closes.
  void close() {
    receivePort.close();
    service._removeClient(this);
  }

  /// Call to process a message. Response will be posted with 'seq'.
  void onMessage(var seq, Message message) {
    // Call post when the response arrives.
    message.response.then((response) {
      post(seq, response);
    });
    // Send message to service.
    service.route(message);
  }

  /// When implementing, responsible for sending [response] to the client.
  void post(var seq, String response);

  dynamic toJson() {
    return {
    };
  }
}
