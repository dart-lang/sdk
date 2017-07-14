// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._vmservice;

typedef void ClientServiceHandle(Message response);

// A service client.
abstract class Client {
  final VMService service;
  final bool sendEvents;

  /// A set streamIds which describes the streams the client is connected to
  final Set<String> streams = new Set<String>();

  /// Services registered and their aliases
  /// key: service
  /// value: alias
  final Map<String, String> services = new Map<String, String>();

  /// Callbacks registered for service invocations set to the client
  /// key: RPC id used for the request
  /// value: callback that should be invoked
  final Map<String, ClientServiceHandle> serviceHandles =
      new Map<String, ClientServiceHandle>();

  Client(this.service, {bool sendEvents: true}) : this.sendEvents = sendEvents {
    service._addClient(this);
  }

  // Disconnects the client.
  disconnect();

  /// When implementing, call [close] when the network connection closes.
  void close() {
    service._removeClient(this);
  }

  /// Call to process a request. Response will be posted with 'seq'.
  void onRequest(Message message) {
    // In JSON-RPC 2.0 messages with and id are Request and must be answered
    // http://www.jsonrpc.org/specification#notification
    service.routeRequest(message).then((response) => post(response));
  }

  void onResponse(Message message) {
    service.routeResponse(message);
  }

  /// Call to process a notification. Response will not be posted.
  void onNotification(Message message) {
    // In JSON-RPC 2.0 messages without an id are Notification
    // and should not be answered
    // http://www.jsonrpc.org/specification#notification
    service.routeRequest(message);
  }

  // Sends a result to the client.  Implemented in subclasses.
  void post(dynamic result);

  dynamic toJson() {
    return {};
  }
}
