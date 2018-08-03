// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library start_paused_test;

import "dart:isolate";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void isomain(SendPort p) {
  p.send("DONE");
}

void notyet(_) {
  throw "NOT YET";
}

void main() {
  asyncStart();
  test1();
  test2();
  asyncEnd();
}

void test1() {
  // Test that a paused isolate doesn't send events.
  // We start two isolates, one paused and one not.
  // The unpaused one must send an event, after which
  // we resume that paused isolate, and expect the second event.
  // This is not a guaranteed test, since it can succeede even if the
  // paused isolate isn't really paused.
  // However, it must never fail, since that would mean that a paused
  // isolate sends a message.
  asyncStart();
  RawReceivePort p1 = new RawReceivePort(notyet);
  Isolate.spawn(isomain, p1.sendPort, paused: true).then((isolate) {
    RawReceivePort p2;
    p2 = new RawReceivePort((x) {
      Expect.equals("DONE", x);
      p2.close();
      p1.handler = (x) {
        Expect.equals("DONE", x);
        p1.close();
        asyncEnd();
      };
      isolate.resume(isolate.pauseCapability);
    });
    Isolate.spawn(isomain, p2.sendPort);
  });
}

void test2() {
  // Test that a paused isolate doesn't send events.
  // Like the test above, except that we change the pause capability
  // of the paused isolate by pausing it using another capability and
  // then resuming the initial pause. This must not cause it to send
  // a message before the second pause is resumed as well.
  asyncStart();
  RawReceivePort p1 = new RawReceivePort(notyet);
  Isolate.spawn(isomain, p1.sendPort, paused: true).then((isolate) {
    RawReceivePort p2;
    Capability c2 = new Capability();
    // Switch to another pause capability.
    isolate.pause(c2);
    isolate.resume(isolate.pauseCapability);
    p2 = new RawReceivePort((x) {
      Expect.equals("DONE", x);
      p2.close();
      p1.handler = (x) {
        Expect.equals("DONE", x);
        p1.close();
        asyncEnd();
      };
      isolate.resume(c2);
    });
    Isolate.spawn(isomain, p2.sendPort);
  });
}
