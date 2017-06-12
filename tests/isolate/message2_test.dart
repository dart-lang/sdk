// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library Message2Test;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

// ---------------------------------------------------------------------------
// Message passing test 2.
// ---------------------------------------------------------------------------

class MessageTest {
  static void mapEqualsDeep(Map expected, Map actual) {
    expect(expected, isMap);
    expect(actual, isMap);
    expect(actual.length, expected.length);
    testForEachMap(key, value) {
      if (value is List) {
        listEqualsDeep(value, actual[key]);
      } else {
        expect(actual[key], value);
      }
    }

    expected.forEach(testForEachMap);
  }

  static void listEqualsDeep(List expected, List actual) {
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] is List) {
        listEqualsDeep(expected[i], actual[i]);
      } else if (expected[i] is Map) {
        mapEqualsDeep(expected[i], actual[i]);
      } else {
        expect(actual[i], expected[i]);
      }
    }
  }
}

void pingPong(replyPort) {
  ReceivePort port = new ReceivePort();
  port.listen((message) {
    if (message == null) {
      port.close();
    } else {
      // Bounce the received object back so that the sender
      // can make sure that the object matches.
      message[1].send(message[0]);
    }
  });
  replyPort.send(port.sendPort);
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("map is equal after it is sent back and forth", () {
    ReceivePort port = new ReceivePort();
    Isolate.spawn(pingPong, port.sendPort);
    port.first.then(expectAsync((remote) {
      Map m = new Map();
      m[1] = "eins";
      m[2] = "deux";
      m[3] = "tre";
      m[4] = "four";
      ReceivePort replyPort = new ReceivePort();
      remote.send([m, replyPort.sendPort]);
      replyPort.first.then(expectAsync((var received) {
        MessageTest.mapEqualsDeep(m, received);
        remote.send(null);
      }));
    }));
  });
}
