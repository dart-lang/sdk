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

final RawReceivePort isolateLifecyclePort = new RawReceivePort();
final RawReceivePort scriptLoadPort = new RawReceivePort();

typedef ShutdownCallback();

class VMService extends MessageRouter {
  static VMService _instance;

  /// Collection of currently connected clients.
  final Set<Client> clients = new Set<Client>();

  /// Collection of currently running isolates.
  RunningIsolates runningIsolates = new RunningIsolates();

  /// A port used to receive events from the VM.
  final RawReceivePort eventPort;

  ShutdownCallback onShutdown;

  void _addClient(Client client) {
    clients.add(client);
  }

  void _removeClient(Client client) {
    clients.remove(client);
  }

  void _eventMessageHandler(dynamic eventMessage) {
    for (var client in clients) {
      if (client.sendEvents) {
        client.post(null, eventMessage);
      }
    }
  }

  void _controlMessageHandler(int code,
                              int portId,
                              SendPort sp,
                              String name) {
    switch (code) {
      case Constants.ISOLATE_STARTUP_MESSAGE_ID:
        runningIsolates.isolateStartup(portId, sp, name);
      break;
      case Constants.ISOLATE_SHUTDOWN_MESSAGE_ID:
        runningIsolates.isolateShutdown(portId, sp);
      break;
    }
  }

  void _exit() {
    isolateLifecyclePort.close();
    scriptLoadPort.close();
    for (var client in clients) {
      client.close();
    }
    // Call embedder shutdown hook after the internal shutdown.
    if (onShutdown != null) {
      onShutdown();
    }
    _onExit();
  }

  void messageHandler(message) {
    if (message is String) {
      // This is an event intended for all clients.
      _eventMessageHandler(message);
      return;
    }
    if (message is Uint8List) {
      // This is "raw" data intended for a specific client.
      //
      // TODO(turnidge): Do not broadcast this data to all clients.
      _eventMessageHandler(message);
      return;
    }
    if (message is List) {
      // This is an internal vm service event.
      if (message.length == 1) {
        // This is a control message directing the vm service to exit.
        assert(message[0] == Constants.SERVICE_EXIT_MESSAGE_ID);
        _exit();
        return;
      }
      if (message.length == 4) {
        // This is a message informing us of the birth or death of an
        // isolate.
        _controlMessageHandler(message[0], message[1], message[2], message[3]);
        return;
      }
    }

    Logger.root.severe(
        'Internal vm-service error: ignoring illegal message: $message');
  }

  void _notSupported(_) {
    throw new UnimplementedError('Service script loading not supported.');
  }

  VMService._internal()
      : eventPort = isolateLifecyclePort {
    scriptLoadPort.handler = _notSupported;
    eventPort.handler = messageHandler;
  }

  factory VMService() {
    if (VMService._instance == null) {
      VMService._instance = new VMService._internal();
      _onStart();
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
    // TODO(turnidge): Update to json rpc.  BEFORE SUBMIT.
    if ((message.path.length == 1) && (message.path[0] == 'clients')) {
      _clientCollection(message);
      return message.response;
    }
    if (message.params['isolateId'] != null) {
      return runningIsolates.route(message);
    }
    return message.sendToVM();
  }
}

RawReceivePort boot() {
  // Return the port we expect isolate startup and shutdown messages on.
  return isolateLifecyclePort;
}

void _registerIsolate(int port_id, SendPort sp, String name) {
  var service = new VMService();
  service.runningIsolates.isolateStartup(port_id, sp, name);
}

void _onStart() native "VMService_OnStart";

void _onExit() native "VMService_OnExit";
