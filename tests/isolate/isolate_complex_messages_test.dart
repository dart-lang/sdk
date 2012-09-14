// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing isolate communication with
// complex messages.

#library('IsolateComplexMessagesTest');
#import('dart:isolate');
#import('../../pkg/unittest/lib/unittest.dart');

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
      Expect.equals(6, message);
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
