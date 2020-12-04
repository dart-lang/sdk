// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--lazy-async-stacks

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 20;
const LINE_B = 21;
const LINE_C = 26;
const LINE_D = 28;
const LINE_E = 31;
const LINE_F = 34;
const LINE_G = 36;

helper() async {
  print('helper'); // LINE_A.
  throw 'a'; // LINE_B.
}

testMain() async {
  debugger();
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
  stoppedAtLine(22), // } (weird dispatching)
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

main([args = const <String>[]]) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
