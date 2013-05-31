// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the event/callback protocol of the stream implementations.
library stream_state_test;

import "../../../pkg/unittest/lib/unittest.dart";
import "stream_state_helper.dart";

const ms5 = const Duration(milliseconds: 5);

main() {
  mainTest(sync: true, broadcast: false);
  mainTest(sync: true, broadcast: true);
  mainTest(sync: false, broadcast: false);
  mainTest(sync: false, broadcast: true);
}

mainTest({bool sync, bool broadcast}) {
  var p = (sync ? "S" : "AS") + (broadcast ? "BC" : "SC");
  test("$p-sub-data-done", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42)
     ..expectDone()
     ..expectCancel();
    t..listen()..add(42)..close();
  });

  test("$p-data-done-sub-sync", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42)
     ..expectDone()
     ..expectCancel();
    t..add(42)..close()..listen();
  });

  test("$p-data-done-sub-async", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42)
     ..expectDone()
     ..expectCancel();
    t..add(42)..close()..listen();
  });

  test("$p-sub-data/pause+resume-done", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42, () {
         t.pause();
         t.resume();
         t.close();
       })
     ..expectDone()
     ..expectCancel();
    t..listen()..add(42);
  });

  test("$p-sub-data-unsubonerror", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42)
     ..expectError("bad")
     ..expectCancel();
    t..listen(cancelOnError: true)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-sub-data-no-unsubonerror", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42)
     ..expectError("bad")
     ..expectData(43)
     ..expectDone()
     ..expectCancel();
    t..listen(cancelOnError: false)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-pause-resume-during-event", () {
    var t = new StreamProtocolTest(sync: sync, broadcast: broadcast);
    t..expectListen()
     ..expectData(42, () {
       t.pause();
       t.resume();
     });
    if (!broadcast && !sync) {
      t..expectPause();
    }
    t..expectDone()
     ..expectCancel();
    t..listen()
     ..add(42)
     ..close();
  });
}
