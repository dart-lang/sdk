// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library TypedDataMessageTest;
import 'dart:isolate';
import 'dart:typeddata';
import '../../pkg/unittest/lib/unittest.dart';

// ---------------------------------------------------------------------------
// Message passing test.
// ---------------------------------------------------------------------------

List elements;

void initializeList() {
  elements = new List(3);
  elements[0] = new Int8List(10);
  for (int j = 0; j < 10; j++) {
    elements[0][j] = j;
  }
  elements[1] = new ByteData.view(elements[0].buffer, 0, 10);
  for (int j = 0; j < 10; j++) {
    elements[1].setInt8(j, j + 100);
  }
  elements[2] = new Int8List.view(new Int8List(100).buffer, 50, 10);
  for (int j = 0; j < 10; j++) {
    elements[2][j] = j + 250;
  }
}

void VerifyList(List expected, List actual) {
  for (int i = 0; i < expected.length; i++) {
    expect(actual[i], expected[i]);
  }
}

void VerifyBytedata(ByteData expected, ByteData actual) {
  for (int i = 0; i < expected.length; i++) {
    expect(actual.getInt8(i), expected.getInt8(i));
  }
}

void VerifyObject(int index, var actual) {
  var expected = elements[index];
  if (expected is List) {
    expect(actual, isList);
    VerifyList(expected, actual);
  } else {
    expect(true, actual is ByteData);
    VerifyBytedata(expected, actual);
  }
  expect(actual.length, expected.length);
}

pingPong() {
  initializeList();
  int count = 0;
  port.receive((var message, SendPort replyTo) {
    if (message == -1) {
      port.close();
      replyTo.send(count, null);
    } else {
      // Check if the received object is correct.
      if (count < elements.length) {
        VerifyObject(count, message);
      }
      // Bounce the received object back so that the sender
      // can make sure that the object matches.
      replyTo.send(message, null);
      count++;
    }
  });
}

main() {
  initializeList();
  test("send objects and receive them back", () {
    SendPort remote = spawnFunction(pingPong);
    // Send objects and receive them back.
    for (int i = 0; i < elements.length; i++) {
      var sentObject = elements[i];
      var idx = i;
      remote.call(sentObject).then(expectAsync1((var receivedObject) {
        VerifyObject(idx, receivedObject);
      }));
    }

    // Shutdown the MessageServer.
    remote.call(-1).then(expectAsync1((int message) {
        expect(message, elements.length);
      }));
  });
}
