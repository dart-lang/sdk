// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--async-debugger --verbose-debug --no-causal-async-stacks --lazy-async-stacks
// VMOptions=--async-debugger --verbose-debug --causal-async-stacks --no-lazy-async-stacks

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 17;
const LINE_B = 18;
const LINE_C = 23;
const LINE_D = 24;

helper() async {
  print('helper'); // LINE_A.
  print('foobar'); // LINE_B.
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_C.
  helper(); // LINE_D.
  print('z');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepInto,

  ...ifLazyAsyncStacks(<IsolateTest>[
    hasStoppedAtBreakpoint,
    stoppedAtLine(16),
    stepInto, // helper() async { ... }
  ]),

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
