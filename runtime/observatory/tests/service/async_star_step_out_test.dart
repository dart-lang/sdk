// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --async_debugger

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 21;
const LINE_B = 22;
const LINE_C = 26;
const LINE_D = 29;
const LINE_E = 36;
const LINE_F = 37;
const LINE_G = 38;
const LINE_H = 27;
const LINE_I = 31;

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
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

var tests = [
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

main(args) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
