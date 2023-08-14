// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 17;
const LINE_B = 18;
const LINE_0 = 22;
const LINE_C = 23;
const LINE_D = 24;
const LINE_E = 25;

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

main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'async_single_step_out_test.dart',
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
    );
