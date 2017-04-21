// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing isolate communication with
// complex messages.

library IsolateComplexMessagesTest;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("complex messages are serialized correctly", () {
    ReceivePort local = new ReceivePort();
    Isolate.spawn(logMessages, local.sendPort);
    var done = expectAsync(() {});
    local.listen(expectAsync((msg) {
      switch (msg[0]) {
        case "init":
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
          local.close();
          expect(msg[1], 6);
          done();
      }
    }, count: 2));
  });
}

void logMessages(mainPort) {
  int count = 0;
  ReceivePort port = new ReceivePort();
  mainPort.send(["init", port.sendPort]);
  port.listen((var message) {
    if (message == -1) {
      port.close();
      mainPort.send(["done", count]);
    } else {
      switch (count) {
        case 0:
          expect(message, 1);
          break;
        case 1:
          expect(message, "Hello");
          break;
        case 2:
          expect(message, "World");
          break;
        case 3:
          expect(message.length, 5);
          expect(message[0], null);
          expect(message[1], 1);
          expect(message[2], 2);
          expect(message[3], 3);
          expect(message[4], 4);
          break;
        case 4:
          expect(message.length, 5);
          expect(message[0], 1);
          expect(message[1], 2.0);
          expect(message[2], true);
          expect(message[3], false);
          expect(message[4], 0xffffffffff);
          break;
        case 5:
          expect(message.length, 3);
          expect(message[0], "Hello");
          expect(message[1], "World");
          expect(message[2], 0xffffffffff);
          break;
      }
      count++;
    }
  });
}
