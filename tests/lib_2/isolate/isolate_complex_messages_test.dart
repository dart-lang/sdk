// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing isolate communication with
// complex messages.

library IsolateComplexMessagesTest;

import 'dart:isolate';

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() {
  asyncStart();

  ReceivePort local = new ReceivePort();
  Isolate.spawn(logMessages, local.sendPort);

  int messagesReceived = 0;
  local.listen((msg) {
    switch (msg[0]) {
      case "init":
        messagesReceived++;
        var remote = msg[1];
        remote.send(1);
        remote.send("Hello");
        remote.send("World");
        remote.send(const [null, 1, 2, 3, 4]);
        remote.send(const [1, 2.0, true, false, 0xffffffffff]);
        remote.send(const ["Hello", "World", 0xffffffffff]);
        // Shutdown the LogRunner.
        remote.send(-1);
        break;
      case "done":
        messagesReceived++;
        local.close();
        Expect.equals(6, msg[1]);
        Expect.equals(2, messagesReceived);
        asyncEnd();
    }
  });
}

void logMessages(mainPort) {
  int count = 0;
  ReceivePort port = new ReceivePort();
  mainPort.send(["init", port.sendPort]);
  port.forEach((var message) {
    if (message == -1) {
      port.close();
      mainPort.send(["done", count]);
    } else {
      switch (count) {
        case 0:
          Expect.equals(1, message);
          break;
        case 1:
          Expect.equals("Hello", message);
          break;
        case 2:
          Expect.equals("World", message);
          break;
        case 3:
          Expect.equals(5, message.length);
          Expect.equals(null, message[0]);
          Expect.equals(1, message[1]);
          Expect.equals(2, message[2]);
          Expect.equals(3, message[3]);
          Expect.equals(4, message[4]);
          break;
        case 4:
          Expect.equals(5, message.length);
          Expect.equals(1, message[0]);
          Expect.equals(2.0, message[1]);
          Expect.equals(true, message[2]);
          Expect.equals(false, message[3]);
          Expect.equals(0xffffffffff, message[4]);
          break;
        case 5:
          Expect.equals(3, message.length);
          Expect.equals("Hello", message[0]);
          Expect.equals("World", message[1]);
          Expect.equals(0xffffffffff, message[2]);
          break;
      }
      count++;
    }
  });
}
