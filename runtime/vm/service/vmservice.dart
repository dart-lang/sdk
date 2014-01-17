// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

part 'client.dart';
part 'constants.dart';
part 'running_isolate.dart';
part 'running_isolates.dart';
part 'message.dart';
part 'message_router.dart';

class VMService extends MessageRouter {
  static VMService _instance;
  /// Collection of currently connected clients.
  final Set<Client> clients = new Set<Client>();
  /// Collection of currently running isolates.
  RunningIsolates runningIsolates = new RunningIsolates();
  /// Isolate startup and shutdown messages are sent on this port.
  final RawReceivePort receivePort;

  void controlMessageHandler(int code, int port_id, SendPort sp, String name) {
    switch (code) {
      case Constants.ISOLATE_STARTUP_MESSAGE_ID:
        runningIsolates.isolateStartup(port_id, sp, name);
      break;
      case Constants.ISOLATE_SHUTDOWN_MESSAGE_ID:
        runningIsolates.isolateShutdown(port_id, sp);
      break;
    }
  }

  void _addClient(Client client) {
    clients.add(client);
  }

  void _removeClient(Client client) {
    clients.remove(client);
  }

  void messageHandler(message) {
    assert(message is List);
    assert(message.length == 4);
    if (message is List && message.length == 4) {
      controlMessageHandler(message[0], message[1], message[2], message[3]);
    }
  }

  VMService._internal() : receivePort = new RawReceivePort() {
    receivePort.handler = messageHandler;
  }

  factory VMService() {
    if (VMService._instance == null) {
      VMService._instance = new VMService._internal();
    }
    return _instance;
  }

  void _clientCollection(Message message) {
    var members = [];
    var result = {};
    clients.forEach((client) {
      members.add(client.toJson());
    });
    result['type'] = 'ClientList';
    result['members'] = members;
    message.setResponse(JSON.encode(result));
  }

  Future<String> route(Message message) {
    if (message.completed) {
      return message.response;
    }
    if ((message.path.length == 1) && (message.path[0] == 'clients')) {
      _clientCollection(message);
      return message.response;
    }
    if (message.path[0] == 'isolates') {
      return runningIsolates.route(message);
    }
    return message.sendToVM();
  }
}

RawReceivePort boot() {
  // Boot the VMService.
  // Return the port we expect isolate startup and shutdown messages on.
  return new VMService().receivePort;
}
