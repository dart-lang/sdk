// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'test_helper.dart';
import 'service_test_common.dart';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

const int LINE_A = 28, LINE_B = 33;

class VMServiceClient {
  VMServiceClient(this.x);
  close() => new Future.microtask(() => print("close"));
  var x;
}

collect() async {
  var uri = "abc";
  var vmService;
  await new Future.microtask(() async {
    try {
      vmService = new VMServiceClient(uri);
      await new Future.microtask(() => throw new TimeoutException("here"));
    } on dynamic {
      vmService.close();
      rethrow; // LINE_A
    }
  });
}

test_code() async {
  try {
    await collect();
  } on TimeoutException {
    print("ok");
  }
}

Future<Isolate> stepThroughProgram(Isolate isolate) async {
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

var tests = [
  hasPausedAtStart,
  markDartColonLibrariesDebuggable,
  setBreakpointAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  setBreakpointAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stepOut,
  stoppedAtLine(LINE_B),
  resumeIsolate
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: test_code, pause_on_start: true, pause_on_exit: false);
