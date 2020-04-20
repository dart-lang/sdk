// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

const int LINE_A = 14;

code() {
  var x = {}; // LINE_A
}

Future stepThroughProgram(Isolate isolate) async {
  Completer completer = new Completer();
  int pauseEventsSeen = 0;

  await subscribeToStream(isolate.vm, VM.kDebugStream,
      (ServiceEvent event) async {
    if (event.kind == ServiceEvent.kPauseBreakpoint) {
      // We are paused: Step further.
      pauseEventsSeen++;
      isolate.stepInto();
    } else if (event.kind == ServiceEvent.kPauseExit) {
      // We are at the exit: The test is done.
      expect(pauseEventsSeen > 20, true,
          reason: "Saw only $pauseEventsSeen pause events.");
      await cancelStreamSubscription(VM.kDebugStream);
      completer.complete();
    }
  });
  isolate.resume();
  return completer.future;
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  markDartColonLibrariesDebuggable,
  setBreakpointAtLine(LINE_A),
  stepThroughProgram
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
