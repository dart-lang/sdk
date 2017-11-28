// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing that isolates can communicate to isolates
// other than the main isolate.

library CrossIsolateMessageTest;

import 'dart:isolate';
import 'package:unittest/unittest.dart';
import "remote_unittest_helper.dart";

/*
 * Everything starts in the main-isolate (in the main-method).
 * The main isolate spawns two isolates: isolate1 (with entry point
 * 'crossIsolate1') and isolate2 (with entry point 'crossIsolate2').
 *
 * The main isolate creates two isolates, isolate1 and isolate2.
 * The second isolate is created with a send-port being listened on by
 * isolate1. A message is passed along this from isolate2 to isolate1.
 * Isolate1 then sends the result back to the main isolate for final checking.
 */

void crossIsolate1(SendPort mainIsolate) {
  ReceivePort local = new ReceivePort();
  mainIsolate.send(["ready1", local.sendPort]);
  local.first.then((msg) {
    // Message from crossIsolate2
    expect(msg[0], "fromIsolate2");
    mainIsolate.send(["fromIsolate1", msg[1] + 58]); // 100.
  });
}

void crossIsolate2(SendPort toIsolate1) {
  toIsolate1.send(["fromIsolate2", 42]);
}

void main([args, port]) {
  if (testRemote(main, port)) return;
  test("send message cross isolates ", () {
    ReceivePort fromIsolate1 = new ReceivePort();
    Isolate.spawn(crossIsolate1, fromIsolate1.sendPort);
    var done = expectAsync(() {});
    fromIsolate1.listen((msg) {
      switch (msg[0]) {
        case "ready1":
          SendPort toIsolate1 = msg[1];
          Isolate.spawn(crossIsolate2, toIsolate1);
          break;
        case "fromIsolate1":
          expect(msg[1], 100);
          fromIsolate1.close();
          break;
        default:
          fail("unreachable! Tag: ${msg[0]}");
      }
    }, onDone: done);
  });
}
