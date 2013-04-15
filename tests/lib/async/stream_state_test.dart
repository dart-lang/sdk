// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the event/callback protocol of the stream implementations.
library stream_state_test;

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
  test("$p-sub-data-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42)..close();
  });

  test("$p-data-done-sub", () {
    var t = new StreamProtocolTest(broadcast);
    if (broadcast) {
      t..expectDone();
    } else {
      t..expectSubscription(true, false)
       ..expectData(42)
       ..expectDone()
       ..expectSubscription(false, false);
    }
    t..add(42)..close()..subscribe();
  });

  test("$p-sub-data/pause+resume-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
         t.pause();
         t.resume();
         t.close();
       })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()..add(42);
  });

  test("$p-sub-data-unsubonerror", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42)
     ..expectError("bad")
     ..expectSubscription(false, !broadcast);
    t..subscribe(cancelOnError: true)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-sub-data-no-unsubonerror", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42)
     ..expectError("bad")
     ..expectData(43)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe(cancelOnError: false)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-pause-resume-during-event", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.pause();
       t.resume();
     })
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42)
     ..close();
  });

  test("$p-cancel-sub-during-event", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.cancel();
       t.subscribe();
     })
     ..expectData(43)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42)
     ..add(43)
     ..close();
  });

  test("$p-cancel-sub-during-callback", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectData(42, () {
       t.pause();
     })
     ..expectPause(true, () {
       t.cancel();  // Cancels pause
       t.subscribe();
     })
     ..expectPause(false)
     ..expectData(43)
     ..expectDone()
     ..expectSubscription(false, false);
    t..subscribe()
     ..add(42)
     ..add(43)
     ..close();
  });

  test("$p-sub-after-done-is-done", () {
    var t = new StreamProtocolTest(broadcast);
    t..expectSubscription(true, false)
     ..expectDone()
     ..expectSubscription(false, false)
     ..expectDone();
    t..subscribe()
     ..close()
     ..subscribe();  // Subscribe after done does not cause callbacks at all.
  });
}
