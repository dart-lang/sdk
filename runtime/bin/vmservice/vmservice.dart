// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

part 'constants.dart';
part 'resources.dart';
part 'running_isolate.dart';
part 'running_isolates.dart';
part 'service_request.dart';
part 'service_request_router.dart';

class VMService {
  static VMService _instance;
  RunningIsolates runningIsolates = new RunningIsolates();
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
}

void sendServiceMessage(SendPort sp, ReceivePort rp, Object m)
    native "SendServiceMessage";
