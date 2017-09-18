// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library illegal_msg_function_test;

import "dart:isolate";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

echo(sendPort) {
  var port = new ReceivePort();
  sendPort.send(port.sendPort);
  port.listen((msg) {
    sendPort.send("echoing ${msg(1)}}");
  });
}

void main() {
  asyncStart();

  final port = new ReceivePort();

  // Ignore returned Future.
  Isolate.spawn(echo, port.sendPort);

  port.first.then((SendPort snd) {
    int function(x) => x + 2;
    try {
      snd.send(function);
    } catch (e) {
      // Expected behavior.
      port.close();
      asyncEnd();
      return;
    }
    Expect.fail("Should not be reached. Message sending didn't throw.");
  });
}
