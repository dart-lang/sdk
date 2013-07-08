// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the event/callback protocol of the stream implementations.
library stream_state_test;

import "../../../pkg/unittest/lib/unittest.dart";
import "stream_state_helper.dart";

const ms5 = const Duration(milliseconds: 5);

main() {
  mainTest(sync: true, asBroadcast: false);
  mainTest(sync: true, asBroadcast: true);
  mainTest(sync: false, asBroadcast: false);
  mainTest(sync: false, asBroadcast: true);
}

mainTest({bool sync, bool asBroadcast}) {
  var p = (sync ? "S" : "AS") + (asBroadcast ? "BC" : "SC");
  test("$p-sub-data-done", () {
    var t = asBroadcast ? new StreamProtocolTest.asBroadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42)
     ..expectDone()
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..listen()..add(42)..close();
  });

  test("$p-data-done-sub-sync", () {
    var t = asBroadcast ? new StreamProtocolTest.asBroadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42)
     ..expectDone()
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..add(42)..close()..listen();
  });

  test("$p-data-done-sub-async", () {
    var t = asBroadcast ? new StreamProtocolTest.asBroadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42)
     ..expectDone()
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..add(42)..close()..listen();
  });

  test("$p-sub-data/pause+resume-done", () {
    var t = asBroadcast ? new StreamProtocolTest.asBroadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42, () {
         t.pause();
         t.resume();
         t.close();
       })
     ..expectDone()
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..listen()..add(42);
  });

  test("$p-sub-data-unsubonerror", () {
    var t = asBroadcast ? new StreamProtocolTest.asBroadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42)
     ..expectError("bad")
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..listen(cancelOnError: true)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-sub-data-no-unsubonerror", () {
    var t = asBroadcast ? new StreamProtocolTest.asBroadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42)
     ..expectError("bad")
     ..expectData(43)
     ..expectDone()
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..listen(cancelOnError: false)
     ..add(42)
     ..error("bad")
     ..add(43)
     ..close();
  });

  test("$p-pause-resume-during-event", () {
    var t = asBroadcast ? new StreamProtocolTest.broadcast(sync: sync)
                        : new StreamProtocolTest(sync: sync);
    t..expectListen()
     ..expectBroadcastListenOpt()
     ..expectData(42, () {
       t.pause();
       t.resume();
     });
    if (!asBroadcast && !sync) {
      t..expectPause();
    }
    t..expectDone()
     ..expectBroadcastCancelOpt()
     ..expectCancel(t.terminate);
    t..listen()
     ..add(42)
     ..close();
  });
}
