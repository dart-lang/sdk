// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

#library('Message2Test');
#import("dart:isolate");
#import("TestFramework.dart");

// ---------------------------------------------------------------------------
// Message passing test 2.
// ---------------------------------------------------------------------------

class MessageTest {
  static void mapEqualsDeep(Map expected, Map actual) {
    Expect.equals(true, expected is Map);
    Expect.equals(true, actual is Map);
    Expect.equals(expected.length, actual.length);
    testForEachMap(key, value) {
      if (value is List) {
        listEqualsDeep(value, actual[key]);
      } else {
        Expect.equals(value, actual[key]);
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
        Expect.equals(expected[i], actual[i]);
      }
    }
  }
}

class PingPongServer extends Isolate {
  PingPongServer() : super.heavy();

  void main() {
    this.port.receive((var message, SendPort replyTo) {
      if (message == -1) {
        this.port.close();
      } else {
        // Bounce the received object back so that the sender
        // can make sure that the object matches.
        replyTo.send(message, null);
      }
    });
  }
}

void test(TestExpectation expect) {
  expect.completes(new PingPongServer().spawn()).then((SendPort remote) {
    Map m = new Map();
    m[1] = "eins";
    m[2] = "deux";
    m[3] = "tre";
    m[4] = "four";
    remote.call(m).then(expect.runs1((var received) {
      MessageTest.mapEqualsDeep(m, received);
      remote.send(-1, null);
      expect.succeeded();
    }));
  });
}

main() {
  runTests([test]);
}
