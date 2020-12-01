// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug --lazy-async-stacks

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 20;
const LINE_B = 21;
const LINE_C = 27;
const LINE_D = 29;
const LINE_E = 32;
const LINE_F = 35;
const LINE_G = 37;

helper() async {
  print('helper'); // LINE_A.
  throw 'a'; // LINE_B.
  return null;
}

testMain() async {
  debugger();
  print('mmmmm'); // LINE_C.
  try {
    await helper(); // LINE_D.
  } on dynamic catch (e) {
    // arrive here on error.
    print('error: $e'); // LINE_E.
  } finally {
    // arrive here in both cases.
    print('foo'); // LINE_F.
  }
  print('z'); // LINE_G.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C), // print mmmm
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D), // await helper
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A), // print helper
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B), // throw a
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(23), // } (weird dispatching)
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D), // await helper (weird dispatching)
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E), // print(error)
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E), // print(error) (weird finally dispatching)
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F), // print(foo)
  smartNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_G), // print(z)
  resumeIsolate
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
