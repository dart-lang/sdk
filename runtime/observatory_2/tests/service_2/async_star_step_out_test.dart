// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 25;
const LINE_B = 26;
const LINE_C = 30;
const LINE_D = 33;
const LINE_E = 40;
const LINE_F = 41;
const LINE_G = 42;
const LINE_H = 31;
const LINE_I = 35;

const LINE_0 = 31;
const LINE_1 = 39;

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
  await for (var i in foobar()) /* LINE_H */ {
    debugger(); // LINE_0.
    print('loop'); // LINE_D.
  }
  return null; // LINE_I.
}

testMain() {
  debugger(); // LINE_1.
  print('mmmmm'); // LINE_E.
  helper(); // LINE_F.
  print('z'); // LINE_G.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_1),
  stepOver, // debugger.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_H), // foobar().
  stepInto,

  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_H), // await for.
  stepInto,

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

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
