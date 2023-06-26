// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 22;
const LINE_B = 23;
const LINE_C = 29;
const LINE_D = 31;
const LINE_E = 34;
const LINE_F = 37;
const LINE_G = 39;

const LINE_0 = 28;

helper() async {
  print('helper'); // LINE_A.
  throw 'a'; // LINE_B.
  return null;
}

testMain() async {
  debugger(); // LINE_0.
  print('mmmmm'); // LINE_C.
  try {
    await helper(); // LINE_D.
  } catch (e) {
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
  stoppedAtLine(LINE_0), // debugger
  stepOver,

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
