// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library MessageTest;

import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

// ---------------------------------------------------------------------------
// Message passing test.
// ---------------------------------------------------------------------------

class MessageTest {
  static const List list1 = const ["Hello", "World", "Hello", 0xfffffffffff];
  static const List list2 = const [null, list1, list1, list1, list1];
  static const List list3 = const [list2, 2.0, true, false, 0xfffffffffff];
  static const Map map1 = const {
    "a=1": 1,
    "b=2": 2,
    "c=3": 3,
  };
  static const Map map2 = const {
    "list1": list1,
    "list2": list2,
    "list3": list3,
  };
  static const List list4 = const [map1, map2];
  static const List elms = const [
    list1,
    list2,
    list3,
    list4,
  ];

  static void VerifyMap(Map expected, Map actual) {
    expect(expected, isMap);
    expect(actual, isMap);
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

pingPong(replyTo) {
  ReceivePort port = new ReceivePort();
  int count = 0;
  port.listen((pair) {
    var message = pair[0];
    var replyTo = pair[1];
    if (message == -1) {
      port.close();
      replyTo.send(count);
    } else {
      // Check if the received object is correct.
      if (count < MessageTest.elms.length) {
        MessageTest.VerifyObject(count, message);
      }
      // Bounce the received object back so that the sender
      // can make sure that the object matches.
      replyTo.send(message);
      count++;
    }
  });
  replyTo.send(port.sendPort);
}

Future remoteCall(SendPort port, message) {
  ReceivePort receivePort = new ReceivePort();
  port.send([message, receivePort.sendPort]);
  return receivePort.first;
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("send objects and receive them back", () {
    ReceivePort port = new ReceivePort();
    Isolate.spawn(pingPong, port.sendPort);
    port.first.then(expectAsync((remote) {
      // Send objects and receive them back.
      for (int i = 0; i < MessageTest.elms.length; i++) {
        var sentObject = MessageTest.elms[i];
        remoteCall(remote, sentObject).then(expectAsync((var receivedObject) {
          MessageTest.VerifyObject(i, receivedObject);
        }));
      }

      // Send recursive objects and receive them back.
      List local_list1 = ["Hello", "World", "Hello", 0xffffffffff];
      List local_list2 = [null, local_list1, local_list1];
      List local_list3 = [local_list2, 2.0, true, false, 0xffffffffff];
      List sendObject = new List(5);
      sendObject[0] = local_list1;
      sendObject[1] = sendObject;
      sendObject[2] = local_list2;
      sendObject[3] = sendObject;
      sendObject[4] = local_list3;
      remoteCall(remote, sendObject).then((var replyObject) {
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
      remoteCall(remote, -1).then(expectAsync((int message) {
        expect(message, MessageTest.elms.length + 1);
      }));
    }));
  });
}
