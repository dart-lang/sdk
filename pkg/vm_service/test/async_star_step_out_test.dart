// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no-causal-async-stacks --lazy-async-stacks
// VMOptions=--causal-async-stacks --no-lazy-async-stacks

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 22;
const LINE_B = 23;
const LINE_C = 27;
const LINE_D = 31;
const LINE_E = 38;
const LINE_F = 39;
const LINE_G = 40;
const LINE_H = 29;
const LINE_I = 33;

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
  // ignore: unused_local_variable
  await for (var i in foobar()) /* LINE_H */ {
    debugger();
    print('loop'); // LINE_D.
  }
  return null; // LINE_I.
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_E.
  helper(); // LINE_F.
  print('z'); // LINE_G.
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
    stoppedAtLine(26), // helper() async { ... }
    stepInto,
  ]),

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stepInto,

  ...ifLazyAsyncStacks(<IsolateTest>[
    hasStoppedAtBreakpoint,
    stoppedAtLine(29), // await for (...) {}
    stepInto,
  ]),

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOut, // step out of generator.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_H), // await for.
  stepInto,

  hasStoppedAtBreakpoint, // debugger().
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D), // print.
  stepInto,

  hasStoppedAtBreakpoint, // await for.
  stepInto,

  hasStoppedAtBreakpoint, // back in generator.
  stoppedAtLine(LINE_B),
  stepOut, // step out of generator.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_H), // await for.
  stepInto,

  hasStoppedAtBreakpoint, // debugger().
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D), // print.
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_H), // await for.
  stepInto,

  hasStoppedAtBreakpoint,
  stepOut, // step out of generator.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_I), // return null.
];

main([args = const <String>[]]) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
