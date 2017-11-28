// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";

void isomain(SendPort replyPort) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (v) {
    if (v == 0) {
      // Shut down when receiving the 0 message.
      port.close();
    } else {
      replyPort.send(v);
    }
  };
  replyPort.send(port.sendPort);
}

void main() {
  testExit();
  testCancelExit();
  testOverrideResponse();
}

void testExit() {
  bool mayComplete = false;
  asyncStart();
  var completer = new Completer(); // Completed by first reply from isolate.
  RawReceivePort reply = new RawReceivePort(completer.complete);
  RawReceivePort onExitPort;
  onExitPort = new RawReceivePort((v) {
    if (v != "RESPONSE") throw "WRONG RESPONSE: $v";
    reply.close();
    onExitPort.close();
    if (!mayComplete) throw "COMPLETED EARLY";
    asyncEnd();
  });
  Isolate.spawn(isomain, reply.sendPort).then((Isolate isolate) {
    isolate.addOnExitListener(onExitPort.sendPort, response: "RESPONSE");
    return completer.future;
  }).then((echoPort) {
    int counter = 4;
    reply.handler = (v) {
      if (v != counter) throw "WRONG REPLY";
      if (v == 0) throw "REPLY INSTEAD OF SHUTDOWN";
      counter--;
      mayComplete = (counter == 0);
      echoPort.send(counter);
    };
    echoPort.send(counter);
  });
}

void testCancelExit() {
  bool mayComplete = false;
  asyncStart();
  var completer = new Completer(); // Completed by first reply from isolate.
  RawReceivePort reply = new RawReceivePort(completer.complete);
  RawReceivePort onExitPort2 = new RawReceivePort((_) {
    throw "RECEIVED EXIT MESSAGE";
  });
  RawReceivePort onExitPort1;
  onExitPort1 = new RawReceivePort((_) {
    reply.close();
    onExitPort1.close();
    if (!mayComplete) throw "COMPLETED EARLY";
    new Timer(const Duration(milliseconds: 0), () {
      onExitPort2.close();
      asyncEnd();
    });
  });
  Isolate.spawn(isomain, reply.sendPort).then((Isolate isolate) {
    isolate.addOnExitListener(onExitPort2.sendPort);
    isolate.addOnExitListener(onExitPort1.sendPort);
    return completer.future.then((echoPort) {
      int counter = 4;
      reply.handler = (v) {
        if (v != counter) throw "WRONG REPLY";
        if (v == 0) throw "REPLY INSTEAD OF SHUTDOWN";
        counter--;
        mayComplete = (counter == 0);
        if (counter == 1) {
          // Remove listener 2, keep listener 1.
          isolate.removeOnExitListener(onExitPort2.sendPort);
        }
        echoPort.send(counter);
      };
      echoPort.send(counter);
    });
  });
}

void testOverrideResponse() {
  bool mayComplete = false;
  asyncStart();
  var completer = new Completer(); // Completed by first reply from isolate.
  RawReceivePort reply = new RawReceivePort(completer.complete);
  RawReceivePort onExitPort;
  onExitPort = new RawReceivePort((v) {
    if (v != "RESPONSE2") throw "WRONG RESPONSE: $v";
    reply.close();
    onExitPort.close();
    if (!mayComplete) throw "COMPLETED EARLY";
    asyncEnd();
  });
  Isolate.spawn(isomain, reply.sendPort).then((Isolate isolate) {
    isolate.addOnExitListener(onExitPort.sendPort, response: "RESPONSE");
    isolate.addOnExitListener(onExitPort.sendPort, response: "RESPONSE2");
    return completer.future;
  }).then((echoPort) {
    int counter = 4;
    reply.handler = (v) {
      if (v != counter) throw "WRONG REPLY";
      if (v == 0) throw "REPLY INSTEAD OF SHUTDOWN";
      counter--;
      mayComplete = (counter == 0);
      echoPort.send(counter);
    };
    echoPort.send(counter);
  });
}
