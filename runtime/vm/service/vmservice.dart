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

  // A map encoding which clients are interested in which kinds of events.
  final Map<int, Set<Client>> eventMap = new Map<int, Set<Client>>();

  /// Collection of currently running isolates.
  RunningIsolates runningIsolates = new RunningIsolates();

  /// A port used to receive events from the VM.
  final RawReceivePort eventPort;

  void _addClient(Client client) {
    clients.add(client);
  }

  void _removeClient(Client client) {
    clients.remove(client);
  }

  int eventTypeCode(String eventType) {
    switch(eventType) {
      case 'debug':
        return Constants.EVENT_FAMILY_DEBUG;
      case 'gc':
        return Constants.EVENT_FAMILY_GC;
      default:
        return -1;
    }
  }

  void _updateEventMask() {
    int mask = 0;
    for (var key in eventMap.keys) {
      var subscribers = eventMap[key];
      if (subscribers.isNotEmpty) {
        mask |= (1 << key);
      }
    }
    _setEventMask(mask);
  }

  void subscribe(String eventType, Client client) {
    int eventCode = eventTypeCode(eventType);
    assert(eventCode >= 0);
    var subscribers = eventMap.putIfAbsent(eventCode, () => new Set<Client>());
    subscribers.add(client);
    _updateEventMask();
  }

  void _controlMessageHandler(int code,
                              int port_id,
                              SendPort sp,
                              String name) {
    switch (code) {
      case Constants.ISOLATE_STARTUP_MESSAGE_ID:
        runningIsolates.isolateStartup(port_id, sp, name);
      break;
      case Constants.ISOLATE_SHUTDOWN_MESSAGE_ID:
        runningIsolates.isolateShutdown(port_id, sp);
      break;
    }
  }

  void _eventMessageHandler(int eventType, String eventMessage) {
    var subscribers = eventMap[eventType];
    if (subscribers == null) {
      return;
    }
    for (var subscriber in subscribers) {
      subscriber.post(null, eventMessage);
    }
  }

  void messageHandler(message) {
    assert(message is List);
    if (message is List && message.length == 4) {
      _controlMessageHandler(message[0], message[1], message[2], message[3]);
    } else if (message is List && message.length == 2) {
      _eventMessageHandler(message[0], message[1]);
    } else {
      Logger.root.severe('Unexpected message: $message');
    }
  }

  VMService._internal()
      : eventPort = new RawReceivePort() {
    eventPort.handler = messageHandler;
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
  return new VMService().eventPort;
}

void _registerIsolate(int port_id, SendPort sp, String name) {
  var service = new VMService();
  service.runningIsolates.isolateStartup(port_id, sp, name);
}

void _setEventMask(int mask)
    native "VMService_SetEventMask";
