// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug

import 'package:observatory/service_io.dart';
import 'test_helper.dart';
import 'dart:developer';

foo() async { }

doAsync(stop) async {
  if (stop) debugger();
  await foo(); // Line 14.
  await foo(); // Line 15.
  await foo(); // Line 16.
  return null;
}

testMain() {
  // With two runs of doAsync floating around, async step should only cause
  // us to stop in the run we started in.
  doAsync(false);
  doAsync(true);
}

asyncNext(Isolate isolate) async {
  return isolate.asyncStepOver()[Isolate.kSecondResume];
}

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(14),
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(15),
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(16),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
