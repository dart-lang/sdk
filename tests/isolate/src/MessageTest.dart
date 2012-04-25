// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

#library('MessageTest');
#import("dart:isolate");
#import('../../../lib/unittest/unittest.dart');

// ---------------------------------------------------------------------------
// Message passing test.
// ---------------------------------------------------------------------------

class MessageTest {
  static final List list1 = const ["Hello", "World", "Hello", 0xfffffffffff];
  static final List list2 = const [null, list1, list1, list1, list1];
  static final List list3 = const [list2, 2.0, true, false, 0xfffffffffff];
  static final Map map1 = const {
    "a=1" : 1, "b=2" : 2, "c=3" : 3,
  };
  static final Map map2 = const {
    "list1" : list1, "list2" : list2, "list3" : list3,
  };
  static final List list4 = const [map1, map2];
  static final List elms = const [
      list1, list2, list3, list4,
  ];

  static void VerifyMap(Map expected, Map actual) {
    Expect.equals(true, expected is Map);
    Expect.equals(true, actual is Map);
    Expect.equals(expected.length, actual.length);
    testForEachMap(key, value) {
      if (value is List) {
        VerifyList(value, actual[key]);
      } else {
        Expect.equals(value, actual[key]);
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
        Expect.equals(expected[i], actual[i]);
      }
    }
  }

  static void VerifyObject(int index, var actual) {
    var expected = elms[index];
    Expect.equals(true, expected is List);
    Expect.equals(true, actual is List);
    Expect.equals(expected.length, actual.length);
    VerifyList(expected, actual);
  }
}

class PingPongServer extends Isolate {
  PingPongServer() : super() {}

  void main() {
    int count = 0;
    this.port.receive(
        (var message, SendPort replyTo) {
          if (message == -1) {
            this.port.close();
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
}

main() {
  test("send objects and receive them back", () {
    new PingPongServer().spawn().then(expectAsync1((SendPort remote) {

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
        Expect.equals(true, sendObject is List);
        Expect.equals(true, replyObject is List);
        Expect.equals(sendObject.length, replyObject.length);
        Expect.equals(true, replyObject[1] === replyObject);
        Expect.equals(true, replyObject[3] === replyObject);
        Expect.equals(true, replyObject[0] === replyObject[2][1]);
        Expect.equals(true, replyObject[0] === replyObject[2][2]);
        Expect.equals(true, replyObject[2] === replyObject[4][0]);
        Expect.equals(true, replyObject[0][0] === replyObject[0][2]);
        // Bigint literals are not canonicalized so do a == check.
        Expect.equals(true, replyObject[0][3] == replyObject[4][4]);
      });

      // Shutdown the MessageServer.
      remote.call(-1).then(expectAsync1((int message) {
          Expect.equals(MessageTest.elms.length + 1, message);
        }));
    }));
  });
}
