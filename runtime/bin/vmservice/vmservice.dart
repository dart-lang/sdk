// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice;

import 'dart:async';
import 'dart:json' as JSON;
// TODO(11927): Factor 'dart:io' dependency into separate library.
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:utf' as UTF;


class VmService {
  static VmService _instance;
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

  VmService._internal() {
    port.receive(messageHandler);
  }

  factory VmService() {
    if (VmService._instance == null) {
      VmService._instance = new VmService._internal();
    }
    return _instance;
  }
}

void sendServiceMessage(SendPort sp, ReceivePort rp, Object m)
    native "SendServiceMessage";
