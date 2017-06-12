// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library handle_error_test;

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

isomain1(replyPort) {
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
  RawReceivePort reply = new RawReceivePort(null);
  // Start paused so we have time to set up the error handler.
  Isolate.spawn(isomain1, reply.sendPort, paused: true).then((Isolate isolate) {
    isolate.setErrorsFatal(false);
    Stream errors = isolate.errors; // Broadcast stream, never a done message.
    SendPort sendPort;
    StreamSubscription subscription;
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
    subscription = errors.listen(null, onError: (error, stack) {
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
          subscription.cancel();
          asyncEnd();
          break;
        default:
          throw "Bad state for error: $state: $error";
      }
    });
    isolate.resume(isolate.pauseCapability);
  });
}
