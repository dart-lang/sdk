// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing isolate communication with
// complex messages.

library IsolateComplexMessagesTest;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

main() {
  test("complex messages are serialized correctly", () {
    SendPort remote = spawnFunction(logMessages);
    remote.send(1, null);
    remote.send("Hello", null);
    remote.send("World", null);
    remote.send(const [null, 1, 2, 3, 4], null);
    remote.send(const [1, 2.0, true, false, 0xffffffffff], null);
    remote.send(const ["Hello", "World", 0xffffffffff], null);
    // Shutdown the LogRunner.
    remote.call(-1).then(expectAsync1((int message) {
      expect(message, 6);
    }));
  });
}


void logMessages() {
  int count = 0;

  port.receive((var message, SendPort replyTo) {
    if (message == -1) {
      port.close();
      replyTo.send(count, null);
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
