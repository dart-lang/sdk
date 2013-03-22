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
    var box = new MessageBox();
    IsolateSink remote = streamSpawnFunction(logMessages);
    remote.add(1);
    remote.add("Hello");
    remote.add("World");
    remote.add(const [null, 1, 2, 3, 4]);
    remote.add(const [1, 2.0, true, false, 0xffffffffff]);
    remote.add(const ["Hello", "World", 0xffffffffff]);
    remote.add(box.sink);
    remote.close();
    box.stream.single.then((message) {
      expect(message, 7);
    });
  });
}


void logMessages() {
  int count = 0;
  IsolateSink replySink;

  stream.listen((message) {
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
      case 6:
        replySink = message;
        break;
    }
    count++;
  },
  onDone: () {
    replySink.add(count);
    replySink.close();
  });
}
