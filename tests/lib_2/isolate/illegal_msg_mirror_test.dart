// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library illegal_msg_mirror_test;

import "dart:isolate";
@MirrorsUsed(targets: "Class")
import "dart:mirrors";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class Class {
  method() {}
}

echo(sendPort) {
  final port = new ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((msg) {
    sendPort.send("echoing ${msg(1)}}");
  });
}

void main([args, port]) {
  asyncStart();

  final ReceivePort port = new ReceivePort();

  // Ignore returned Future.
  Isolate.spawn(echo, port.sendPort);

  port.first.then((SendPort snd) {
    final methodMirror = reflectClass(Class).declarations[#method];
    try {
      snd.send(methodMirror);
    } catch (e) {
      // Expected behavior.
      port.close();
      asyncEnd();
      return;
    }
    Expect.fail("Should not be reached. Message sending didn't throw.");
  });
}
