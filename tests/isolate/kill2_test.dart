// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

isomain1(replyPort) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (v) {
    replyPort.send(v);
    if (v == 0) port.close();
  };
  replyPort.send(port.sendPort);
}

void main() {
  asyncStart();
  var completer = new Completer(); // Completed by first reply from isolate.
  RawReceivePort reply = new RawReceivePort(completer.complete);
  Isolate.spawn(isomain1, reply.sendPort).then((Isolate isolate) {
    List result = [];
    completer.future.then((echoPort) {
      reply.handler = (v) {
        result.add(v);
        if (v == 2) {
          isolate.kill(priority: Isolate.BEFORE_NEXT_EVENT);
        }
        echoPort.send(v - 1);
      };
      RawReceivePort exitSignal;
      exitSignal = new RawReceivePort((_) {
        Expect.listEquals([4, 3, 2], result);
        exitSignal.close();
        reply.close();
        asyncEnd();
      });
      isolate.addOnExitListener(exitSignal.sendPort);
      echoPort.send(4);
    });
  });
}
