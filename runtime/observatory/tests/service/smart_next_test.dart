// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';

foo() async { }
bar() { }

doAsync(stop) async {
  if (stop) debugger();
  await foo(); // Line 16.
  bar();       // Line 17.
  bar();       // Line 18.
  await foo(); // Line 19.
  await foo(); // Line 20.
  bar();       // Line 21.
  return null;
}

testMain() {
  // With two runs of doAsync floating around, async step should only cause
  // us to stop in the run we started in.
  doAsync(false);
  doAsync(true);
}

stepOverAwaitingResume(Isolate isolate) async {
  Completer completer = new Completer();
  await isolate.vm.getEventStream(VM.kDebugStream).then((stream) {
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kResume) {
        subscription.cancel();
        completer.complete();
      }
    });
  });
  isolate.stepOver();
  return completer.future;
}

smartNext(Isolate isolate) async {
  if (isolate.pauseEvent.atAsyncJump) {
    print("next-async");
    return isolate.asyncStepOver()[Isolate.kSecondResume];
  } else {
    print("next-sync");
    return stepOverAwaitingResume(isolate);
  }
}

var tests = [
             hasStoppedAtBreakpoint, stoppedAtLine(16), // foo()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(16), // await
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(17), // bar()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(18), // bar()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(19), // foo()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(19), // await
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(20), // foo()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(20), // await
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(21), // bar()
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
