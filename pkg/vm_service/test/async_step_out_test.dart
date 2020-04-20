// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-causal-async-stacks --lazy-async-stacks
// VMOptions=--causal-async-stacks --no-lazy-async-stacks

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 19;
const LINE_B = 20;
const LINE_C = 21;
const LINE_D = 26;
const LINE_E = 27;
const LINE_F = 28;

helper() async {
  await null; // LINE_A.
  print('helper'); // LINE_B.
  print('foobar'); // LINE_C.
}

testMain() async {
  debugger();
  print('mmmmm'); // LINE_D.
  await helper(); // LINE_E.
  print('z'); // LINE_F.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  stepInto,

  ...ifLazyAsyncStacks(<IsolateTest>[
    hasStoppedAtBreakpoint,
    stoppedAtLine(18), // helper() async { ... }
    stepInto,
  ]),

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  asyncNext,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOut, // out of helper to awaiter testMain.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
];

main([args = const <String>[]]) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
