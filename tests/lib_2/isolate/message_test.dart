// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts

library MessageTest;

import 'dart:async';
import 'dart:isolate';

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

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
    Expect.equals(actual.length, expected.length);
    testForEachMap(key, value) {
      if (value is List) {
        VerifyList(value, actual[key]);
      } else {
        Expect.equals(actual[key], value);
      }
    }

    expected.forEach(testForEachMap);
  }

  static void VerifyList(List expected, List actual) {
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] is List) {
        VerifyList(expected[i], actual[i]);
      } else if (expected[i] is Map) {
        Expect.type<Map>(actual[i]);
        VerifyMap(expected[i], actual[i]);
      } else {
        Expect.equals(actual[i], expected[i]);
      }
    }
  }

  static void VerifyObject(int index, var actual) {
    var expected = elms[index];
    Expect.type<List>(expected);
    Expect.type<List>(actual);
    Expect.equals(actual.length, expected.length);
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
  ReceivePort port = new ReceivePort();
  Isolate.spawn(pingPong, port.sendPort);
  asyncStart();
  port.first.then((remote) {
    // Send objects and receive them back.
    for (int i = 0; i < MessageTest.elms.length; i++) {
      var sentObject = MessageTest.elms[i];
      asyncStart();
      remoteCall(remote, sentObject).then((receivedObject) {
        MessageTest.VerifyObject(i, receivedObject);
        asyncEnd();
      });
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
      Expect.type<List>(sendObject);
      Expect.type<List>(replyObject);
      Expect.equals(sendObject.length, replyObject.length);
      Expect.identical(replyObject[1], replyObject);
      Expect.identical(replyObject[3], replyObject);
      Expect.identical(replyObject[0], replyObject[2][1]);
      Expect.identical(replyObject[0], replyObject[2][2]);
      Expect.identical(replyObject[2], replyObject[4][0]);
      Expect.identical(replyObject[0][0], replyObject[0][2]);
      Expect.equals(replyObject[0][3], replyObject[4][4]);
    });

    // Shutdown the MessageServer.
    remoteCall(remote, -1).then((message) {
      Expect.equals(message, MessageTest.elms.length + 1);
      asyncEnd();
    });
  });
}
