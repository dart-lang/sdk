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

/// Do Isolate.spawn(entry) and get a sendPort from the isolate that it
/// expects commands on.
/// The isolate has errors set to non-fatal.
/// Returns a list of `[isolate, commandPort]` in a future.
Future spawn(entry) {
  ReceivePort reply = new ReceivePort();
  Future isolate = Isolate.spawn(entry, reply.sendPort, paused: true);
  return isolate.then((Isolate isolate) {
    isolate.setErrorsFatal(false);
    isolate.resume(isolate.pauseCapability);
    Future result = reply.first.then((sendPort) {
      return [isolate, sendPort];
    });
    return result;
  });
}

main() {
  asyncStart();
  RawReceivePort reply = new RawReceivePort(null);
  // Create two isolates waiting for commands, with errors non-fatal.
  Future iso1 = spawn(isomain1);
  Future iso2 = spawn(isomain1);
  Future.wait([iso1, iso2]).then((l) {
    var isolate1 = l[0][0];
    var sendPort1 = l[0][1];
    var isolate2 = l[1][0];
    var sendPort2 = l[1][1];
    Stream errors = isolate1.errors; // Broadcast stream, never a done message.
    int state = 1;
    var subscription;
    subscription = errors.listen(null, onError: (error, stack) {
      switch (state) {
        case 1:
          Expect.equals(new ArgumentError("whoops").toString(), "$error");
          state++;
          break;
        case 2:
          Expect.equals(new RangeError.value(37).toString(), "$error");
          state++;
          reply.close();
          subscription.cancel();
          asyncEnd();
          break;
        default:
          throw "Bad state for error: $state: $error";
      }
    });
    sendPort1.send(0);
    sendPort2.send(0);
    sendPort1.send(1);
    sendPort2.send(1);
    sendPort1.send(2);
    sendPort2.send(2);
    sendPort1.send(3);
    sendPort2.send(3);
  });
}
