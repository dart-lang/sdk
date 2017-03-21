// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'test_helper.dart';
import 'dart:async';
import 'dart:developer';
import 'service_test_common.dart';

const int LINE_A = 20;

foo() async { }
bar() { }

doAsync(stop) async {
  if (stop) debugger();
  await foo(); // Line A.
  bar();       // Line A + 1.
  bar();       // Line A + 2.
  await foo(); // Line A + 3.
  await foo(); // Line A + 4.
  bar();       // Line A + 5.
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
  if (M.isAtAsyncSuspension(isolate.pauseEvent)) {
    print("next-async");
    return asyncStepOver(isolate);
  } else {
    print("next-sync");
    return stepOverAwaitingResume(isolate);
  }
}

var tests = [
             hasStoppedAtBreakpoint, stoppedAtLine(LINE_A), // foo()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A), // await
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 1), // bar()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 2), // bar()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 3), // foo()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 3), // await
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 4), // foo()
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 4), // await
  smartNext, hasStoppedAtBreakpoint, stoppedAtLine(LINE_A + 5), // bar()
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
