// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the event/callback protocol of the stream implementations.
// Uses a non-zero timer so it fails on d8.

library stream_state_nonzero_timer_test;

import "dart:async";
import "../../../pkg/unittest/lib/unittest.dart";
import "stream_state_helper.dart";

const ms5 = const Duration(milliseconds: 5);

main() {
  mainTest(false);
  // TODO(floitsch): reenable?
  // mainTest(true);
}

mainTest(bool broadcast) {
  var p = broadcast ? "BC" : "SC";

  test("$p-sub-data/pause/resume/pause/resume-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause();
       })
     ..expectPause(true, () { t.resume(); })
     ..expectPause(false, () { t.pause(); })
     ..expectPause(true, () { t.resume(); })
     ..expectPause(false, () { t.close(); })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data/pause-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause(new Future.delayed(ms5, () => null));
       })
     ..expectPause(true)
     ..expectDone()
     ..expectSubscription(false, false);
     // We are calling "close" while the controller is actually paused,
     // and it will stay paused until the pending events are sent.
    t..subscribe()..add(42)..close();
  });

  test("$p-sub-data/pause-resume/done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause(new Future.delayed(ms5, () => null));
       })
     ..expectPause(true)
     ..expectPause(false, () { t.close(); })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data/data+pause-data-resume-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.add(43);
         t.pause(new Future.delayed(ms5, () => null));
         // Should now be paused until the future finishes.
         // After that, the controller stays paused until the pending queue
         // is empty.
       })
     ..expectPause(true)
     ..expectData(43)
     ..expectPause(false, () { t.close(); })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-pause-during-callback", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.pause();
     })
     ..expectPause(true, () {
       t.resume();
     })
     ..expectPause(false, () {
       t.pause();
       t.resume();
       t.close();
     })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42);
  });
}
