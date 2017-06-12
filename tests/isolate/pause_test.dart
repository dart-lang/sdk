// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:isolate";
import "dart:async";
import "package:async_helper/async_helper.dart";

isomain1(replyPort) {
  RawReceivePort port = new RawReceivePort();
  port.handler = (v) {
    replyPort.send(v);
    port.close();
  };
  replyPort.send(port.sendPort);
}

main() {
  asyncStart();
  RawReceivePort reply = new RawReceivePort();
  Isolate isolate;
  Capability resume;
  var completer = new Completer(); // Completed by first reply from isolate.
  reply.handler = completer.complete;
  Isolate.spawn(isomain1, reply.sendPort).then((Isolate iso) {
    isolate = iso;
    return completer.future;
  }).then((echoPort) {
    // Isolate has been created, and first response has been returned.
    resume = isolate.pause();
    echoPort.send(24);
    reply.handler = (v) {
      throw "RESPONSE WHILE PAUSED?!?";
    };
    return new Future.delayed(const Duration(milliseconds: 250));
  }).then((_) {
    reply.handler = (v) {
      if (v != 24) throw "WRONG ANSWER!";
      reply.close();
      asyncEnd();
    };
    isolate.resume(resume);
  });
}
