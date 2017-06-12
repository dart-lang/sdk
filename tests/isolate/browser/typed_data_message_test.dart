// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library TypedDataMessageTest;

import 'dart:isolate';
import 'dart:typed_data';
import 'package:unittest/unittest.dart';
import "../remote_unittest_helper.dart";

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

pingPong(SendPort initialReplyTo) {
  var port = new ReceivePort();
  initialReplyTo.send(port.sendPort);
  initializeList();
  int count = 0;
  port.listen((var message) {
    var data = message[0];
    SendPort replyTo = message[1];
    if (data == -1) {
      port.close();
      replyTo.send(count);
    } else {
      // Check if the received object is correct.
      if (count < elements.length) {
        VerifyObject(count, data);
      }
      // Bounce the received object back so that the sender
      // can make sure that the object matches.
      replyTo.send(data);
      count++;
    }
  });
}

Future sendReceive(SendPort port, msg) {
  ReceivePort response = new ReceivePort();
  port.send([msg, response.sendPort]);
  return response.first;
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  initializeList();
  test("send objects and receive them back", () {
    ReceivePort response = new ReceivePort();
    Isolate.spawn(pingPong, response.sendPort);
    response.first.then((SendPort remote) {
      // Send objects and receive them back.
      for (int i = 0; i < elements.length; i++) {
        var sentObject = elements[i];
        var idx = i;
        sendReceive(remote, sentObject).then(expectAsync((var receivedObject) {
          VerifyObject(idx, receivedObject);
        }));
      }

      // Shutdown the MessageServer.
      sendReceive(remote, -1).then(expectAsync((int message) {
        expect(message, elements.length);
      }));
    });
  });
}
