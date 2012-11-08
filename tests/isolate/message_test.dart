// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library MessageTest;
import 'dart:isolate';
import '../../pkg/unittest/lib/unittest.dart';

// ---------------------------------------------------------------------------
// Message passing test.
// ---------------------------------------------------------------------------

class MessageTest {
  static const List list1 = const ["Hello", "World", "Hello", 0xfffffffffff];
  static const List list2 = const [null, list1, list1, list1, list1];
  static const List list3 = const [list2, 2.0, true, false, 0xfffffffffff];
  static const Map map1 = const {
    "a=1" : 1, "b=2" : 2, "c=3" : 3,
  };
  static const Map map2 = const {
    "list1" : list1, "list2" : list2, "list3" : list3,
  };
  static const List list4 = const [map1, map2];
  static const List elms = const [
      list1, list2, list3, list4,
  ];

  static void VerifyMap(Map expected, Map actual) {
    expect(expected, isMap);
    expect(actual,  isMap);
    expect(actual.length, expected.length);
    testForEachMap(key, value) {
      if (value is List) {
        VerifyList(value, actual[key]);
      } else {
        expect(actual[key], value);
      }
    }
    expected.forEach(testForEachMap);
  }

  static void VerifyList(List expected, List actual) {
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] is List) {
        VerifyList(expected[i], actual[i]);
      } else if (expected[i] is Map) {
        VerifyMap(expected[i], actual[i]);
      } else {
        expect(actual[i], expected[i]);
      }
    }
  }

  static void VerifyObject(int index, var actual) {
    var expected = elms[index];
    expect(expected, isList);
    expect(actual, isList);
    expect(actual.length, expected.length);
    VerifyList(expected, actual);
  }
}

pingPong() {
  int count = 0;
  port.receive((var message, SendPort replyTo) {
    if (message == -1) {
      port.close();
      replyTo.send(count, null);
    } else {
      // Check if the received object is correct.
      if (count < MessageTest.elms.length) {
        MessageTest.VerifyObject(count, message);
      }
      // Bounce the received object back so that the sender
      // can make sure that the object matches.
      replyTo.send(message, null);
      count++;
    }
  });
}

main() {
  test("send objects and receive them back", () {
    SendPort remote = spawnFunction(pingPong);
    // Send objects and receive them back.
    for (int i = 0; i < MessageTest.elms.length; i++) {
      var sentObject = MessageTest.elms[i];
      // TODO(asiva): remove this local var idx once thew new for-loop
      // semantics for closures is implemented.
      var idx = i;
      remote.call(sentObject).then(expectAsync1((var receivedObject) {
        MessageTest.VerifyObject(idx, receivedObject);
      }));
    }

    // Send recursive objects and receive them back.
    List local_list1 = ["Hello", "World", "Hello", 0xffffffffff];
    List local_list2 = [null, local_list1, local_list1 ];
    List local_list3 = [local_list2, 2.0, true, false, 0xffffffffff];
    List sendObject = new List(5);
    sendObject[0] = local_list1;
    sendObject[1] = sendObject;
    sendObject[2] = local_list2;
    sendObject[3] = sendObject;
    sendObject[4] = local_list3;
    remote.call(sendObject).then((var replyObject) {
      expect(sendObject, isList);
      expect(replyObject, isList);
      expect(sendObject.length, equals(replyObject.length));
      expect(replyObject[1], same(replyObject));
      expect(replyObject[3], same(replyObject));
      expect(replyObject[0], same(replyObject[2][1]));
      expect(replyObject[0], same(replyObject[2][2]));
      expect(replyObject[2], same(replyObject[4][0]));
      expect(replyObject[0][0], same(replyObject[0][2]));
      // Bigint literals are not canonicalized so do a == check.
      expect(replyObject[0][3], equals(replyObject[4][4]));
    });

    // Shutdown the MessageServer.
    remote.call(-1).then(expectAsync1((int message) {
        expect(message, MessageTest.elms.length + 1);
      }));
  });
}
