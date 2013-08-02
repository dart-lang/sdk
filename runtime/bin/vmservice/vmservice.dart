// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice;

import 'dart:async';
import 'dart:json' as JSON;
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:utf' as UTF;

part 'constants.dart';
part 'resources.dart';
part 'running_isolate.dart';
part 'running_isolates.dart';
part 'service_request.dart';
part 'service_request_router.dart';

class VMService {
  static VMService _instance;
  RunningIsolates runningIsolates = new RunningIsolates();

  void controlMessageHandler(int code, SendPort sp) {
    switch (code) {
      case Constants.ISOLATE_STARTUP_MESSAGE_ID:
        runningIsolates.isolateStartup(sp);
      break;
      case Constants.ISOLATE_SHUTDOWN_MESSAGE_ID:
        runningIsolates.isolateShutdown(sp);
      break;
    }
  }

  void messageHandler(message, SendPort replyTo) {
    if (message is List && message.length == 2) {
      controlMessageHandler(message[0], message[1]);
    }
  }

  VMService._internal() {
    port.receive(messageHandler);
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
