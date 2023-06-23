// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 20;
const LINE_B = 21;
const LINE_C = 26;
const LINE_D = 27;
const LINE_E = 28;

const LINE_0 = 25;

helper() async {
  print('helper'); // LINE_A.
  return null; // LINE_B.
}

testMain() async {
  debugger(); // LINE_0.
  print('mmmmm'); // LINE_C.
  await helper(); // LINE_D.
  print('z'); // LINE_E.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0), // debugger
  stepOver,

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
  stoppedAtLine(LINE_D), // await helper
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E), // arrive after the await.
  resumeIsolate
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
