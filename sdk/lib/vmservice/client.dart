// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:_vmservice";

typedef void ClientServiceHandle(Message? response);

// A service client.
abstract class Client {
  final VMService service;
  final bool sendEvents;

  static int _idCounter = 0;
  final int _id = ++_idCounter;

  String get defaultClientName => 'client$_id';

  String get name => _name;
  set name(String? n) => _name = (n ?? defaultClientName);
  late String _name;

  /// The set of streams the client is subscribed to.
  final streams = <String>{};

  /// Pairs of 1) the ID of a Service ID zone created by this client and 2) the
  /// ID of the isolate in which that zone was created.
  final List<({String serviceIdZoneId, String isolateId})>
  createdServiceIdZones = [];

  /// The set of user tags that the client wants to receive CPU samples for.
  final profilerUserTagFilters = <String>{};

  /// Services registered and their aliases
  /// key: service
  /// value: alias
  final services = <String, String>{};

  /// Callbacks registered for service invocations set to the client
  /// key: RPC id used for the request
  /// value: callback that should be invoked
  final serviceHandles = <String, ClientServiceHandle>{};

  Client(this.service, {this.sendEvents = true}) {
    _name = defaultClientName;
    service._addClient(this);
  }

  // Disconnects the client.
  disconnect();

  /// When implementing, call [close] when the network connection closes.
  void close() => service._removeClient(this);

  /// Call to process a request. Response will be posted with 'seq'.
  void onRequest(Message message) =>
      // In JSON-RPC 2.0 messages with and id are Request and must be answered
      // http://www.jsonrpc.org/specification#notification
      service.routeRequest(service, message).then(post);

  void onResponse(Message message) => service.routeResponse(message);

  /// Call to process a notification. Response will not be posted.
  void onNotification(Message message) =>
      // In JSON-RPC 2.0 messages without an id are Notification
      // and should not be answered
      // http://www.jsonrpc.org/specification#notification
      service.routeRequest(service, message);

  // Sends a result to the client. Implemented in subclasses.
  //
  // Null can be passed as response to a JSON-RPC notification to close the
  // connection.
  void post(Response? result);

  Map<String, dynamic> toJson() => {};
}
