// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

isomain1(replyPort) {
  RawReceivePort port = new RawReceivePort();
  bool firstEvent = true;
  port.handler = (v) {
    if (!firstEvent) {
      throw "Survived suicide";
    }
    var controlPort = v[0];
    var killCapability = v[1];
    firstEvent = false;
    var isolate = new Isolate(controlPort, terminateCapability: killCapability);
    isolate.kill(priority: Isolate.IMMEDIATE);
  };
  replyPort.send(port.sendPort);
}

void main() {
  asyncStart();
  var completer = new Completer(); // Completed by first reply from isolate.
  RawReceivePort reply = new RawReceivePort(completer.complete);
  Isolate.spawn(isomain1, reply.sendPort).then((Isolate isolate) {
    completer.future.then((isolatePort) {
      RawReceivePort exitSignal;
      exitSignal = new RawReceivePort((_) {
        exitSignal.close();
        asyncEnd();
      });
      isolate.addOnExitListener(exitSignal.sendPort);
      isolatePort.send([isolate.controlPort, isolate.terminateCapability]);
      reply.close();
    });
  });
}
