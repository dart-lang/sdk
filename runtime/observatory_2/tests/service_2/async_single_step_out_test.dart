// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug --lazy-async-stacks

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 18;
const LINE_B = 19;
const LINE_C = 24;
const LINE_D = 25;
const LINE_E = 26;

helper() async {
  print('helper'); // LINE_A.
  return null; // LINE_B.
}

testMain() async {
  debugger();
  print('mmmmm'); // LINE_C.
  await helper(); // LINE_D.
  print('z'); // LINE_E.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C), // print mmmm
  stepOver,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D), // await helper
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A), // print.
  stepOver,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B), // return null.
  stepInto, // exit helper via a single step.

  hasStoppedAtBreakpoint,
  stoppedAtLine(20), // return null (weird dispatching)
  stepInto, // exit helper via a single step.

  hasStoppedAtBreakpoint,
  stoppedAtLine(25), // await helper (weird dispatching)
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E), // arrive after the await.
  resumeIsolate
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
