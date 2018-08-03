// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --async_debugger

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 18;
const LINE_B = 19;
const LINE_C = 20;
const LINE_D = 25;
const LINE_E = 26;
const LINE_F = 27;

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

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
