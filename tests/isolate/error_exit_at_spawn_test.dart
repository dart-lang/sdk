// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library error_exit_at_spawn;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

isomain(replyPort) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (v) {
    switch (v) {
      case 0:
        replyPort.send(42);
        break;
      case 1:
        throw new ArgumentError("whoops");
      case 2:
        throw new RangeError.value(37);
      case 3:
        port.close();
    }
  };
  replyPort.send(port.sendPort);
}

main() {
  asyncStart();
  // Setup the port for communication with the newly spawned isolate.
  RawReceivePort reply = new RawReceivePort(null);
  SendPort sendPort;
  int state = 0;
  reply.handler = (port) {
    sendPort = port;
    port.send(state);
    reply.handler = (v) {
      Expect.equals(0, state);
      Expect.equals(42, v);
      state++;
      sendPort.send(state);
    };
  };

  // Capture errors from other isolate as raw messages.
  RawReceivePort errorPort = new RawReceivePort();
  errorPort.handler = (message) {
    String error = message[0];
    String stack = message[1];
    switch (state) {
      case 1:
        Expect.equals(new ArgumentError("whoops").toString(), "$error");
        state++;
        sendPort.send(state);
        break;
      case 2:
        Expect.equals(new RangeError.value(37).toString(), "$error");
        state++;
        sendPort.send(state);
        reply.close();
        errorPort.close();
        break;
      default:
        throw "Bad state for error: $state: $error";
    }
  };

  // Get exit notifications from other isolate as raw messages.
  RawReceivePort exitPort = new RawReceivePort();
  exitPort.handler = (message) {
    // onExit ports registered at spawn cannot have a particular message
    // associated.
    Expect.equals(null, message);
    // Only exit after sending the termination message.
    Expect.equals(3, state);
    exitPort.close();
    asyncEnd();
  };

  Isolate.spawn(isomain, reply.sendPort,
      // Setup handlers as part of spawn.
      errorsAreFatal: false,
      onError: errorPort.sendPort,
      onExit: exitPort.sendPort);
}
