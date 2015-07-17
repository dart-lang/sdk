// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile_all --error_on_bad_type --error_on_bad_override  --verbose_debug

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:developer';

foo() async { }

doAsync(stop) async {
  if (stop) debugger();
  await foo(); // Line 15.
  await foo(); // Line 16.
  await foo(); // Line 17.
  return null;
}

testMain() {
  // With two runs of doAsync floating around, async step should only cause
  // us to stop in the run we started in.
  doAsync(false);
  doAsync(true);
}


asyncStep(Isolate isolate) async {
  var event = isolate.pauseEvent;
  print("Pause event is $event");
  expect(event, isNotNull);

  // 1. Set breakpoint for the continuation and resume the isolate.
  Instance continuation = event.asyncContinuation;
  print("Async continuation is $continuation");
  if (continuation == null) {
    print(await isolate.getStack());
  }
  expect(continuation.isClosure, isTrue);

  var bpt = await isolate.addBreakOnActivation(continuation);
  print("Async step to $bpt");
  expect(bpt is Breakpoint, isTrue);

  await isolate.resume();
  await hasStoppedAtBreakpoint(isolate);
  print("Big step to: ${isolate.pauseEvent}");

  // 2. Step past the state-machine dispatch.
  await isolate.stepOver();
  await hasStoppedAtBreakpoint(isolate);
  print("Small step to: ${isolate.pauseEvent}");
}

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(15),
  asyncStep,
  stoppedAtLine(16),
  asyncStep,
  stoppedAtLine(17),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
