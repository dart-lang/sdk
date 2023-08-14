// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 19;
const LINE_B = 20;
const LINE_0 = 24;
const LINE_C = 25;
const LINE_D = 27;
const LINE_E = 30;
const LINE_F = 33;
const LINE_G = 35;

helper() async {
  print('helper'); // LINE_A.
  throw 'a'; // LINE_B.
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

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'async_single_step_exception_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
