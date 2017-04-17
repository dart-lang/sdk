// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the event/callback protocol of the stream implementations.
// Uses a non-zero timer so it fails on d8.

library stream_state_nonzero_timer_test;

import "dart:async";
import "package:unittest/unittest.dart";
import "stream_state_helper.dart";

const ms5 = const Duration(milliseconds: 5);

// Testing pause/resume, some with non-zero duration. This only makes sense for
// non-broadcast streams, since broadcast stream subscriptions handle their
// own pauses.

main() {
  var p = "StreamController";

  test("$p-sub-data/pause/resume/pause/resume-done", () {
    var t = new StreamProtocolTest();
    t
      ..expectListen()
      ..expectData(42, () {
        t.pause();
      })
      ..expectPause(() {
        t.resume();
      })
      ..expectResume(() {
        t.pause();
      })
      ..expectPause(() {
        t.resume();
      })
      ..expectResume(() {
        t.close();
      })
      ..expectCancel()
      ..expectDone(t.terminate);
    t
      ..listen()
      ..add(42);
  });

  test("$p-sub-data/pause-done", () {
    var t = new StreamProtocolTest();
    t
      ..expectListen()
      ..expectData(42, () {
        t.pause(new Future.delayed(ms5, () => null));
      })
      ..expectPause()
      ..expectCancel()
      ..expectDone(t.terminate);
    // We are calling "close" while the controller is actually paused,
    // and it will stay paused until the pending events are sent.
    t
      ..listen()
      ..add(42)
      ..close();
  });

  test("$p-sub-data/pause-resume/done", () {
    var t = new StreamProtocolTest();
    t
      ..expectListen()
      ..expectData(42, () {
        t.pause(new Future.delayed(ms5, () => null));
      })
      ..expectPause()
      ..expectResume(t.close)
      ..expectCancel()
      ..expectDone(t.terminate);
    t
      ..listen()
      ..add(42);
  });

  test("$p-sub-data/data+pause-data-resume-done", () {
    var t = new StreamProtocolTest();
    t
      ..expectListen()
      ..expectData(42, () {
        t.add(43);
        t.pause(new Future.delayed(ms5, () => null));
        // Should now be paused until the future finishes.
        // After that, the controller stays paused until the pending queue
        // is empty.
      })
      ..expectPause()
      ..expectData(43)
      ..expectResume(t.close)
      ..expectCancel()
      ..expectDone(t.terminate);
    t
      ..listen()
      ..add(42);
  });

  test("$p-pause-during-callback", () {
    var t = new StreamProtocolTest();
    t
      ..expectListen()
      ..expectData(42, () {
        t.pause();
      })
      ..expectPause(() {
        t.resume();
      })
      ..expectResume(() {
        t.pause();
        t.resume();
        t.close();
      })
      ..expectCancel()
      ..expectDone(t.terminate);
    t
      ..listen()
      ..add(42);
  });
}
