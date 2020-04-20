// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--async-debugger --verbose-debug --no-causal-async-stacks --lazy-async-stacks
// VMOptions=--async-debugger --verbose-debug --causal-async-stacks --no-lazy-async-stacks

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 19;
const LINE_B = 20;
const LINE_C = 24;
const LINE_D = 27;
const LINE_E = 33;
const LINE_F = 34;

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
  await for (var i in foobar()) {
    debugger();
    print('loop'); // LINE_D.
  }
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_E.
  helper(); // LINE_F.
  print('z');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
  stepInto,

  ...ifLazyAsyncStacks(<IsolateTest>[
    hasStoppedAtBreakpoint,
    stoppedAtLine(23), // helper() async { ... }
    stepInto,
  ]),

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.

  ...ifLazyAsyncStacks(<IsolateTest>[
    hasStoppedAtBreakpoint,
    stoppedAtLine(25), // await for ...
    stepInto,
  ]),

  hasStoppedAtBreakpoint,
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // Resume here to exit the generator function.
  // TODO(johnmccutchan): Implement support for step-out of async functions.
  resumeIsolate,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
