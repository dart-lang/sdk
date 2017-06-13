// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug --async_debugger

import 'dart:developer';

import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 18;
const LINE_B = 19;
const LINE_C = 24;
const LINE_D = 25;
const LINE_E = 26;

helper() async {
  print('helper'); // LINE_A.
  print('foobar'); // LINE_B.
}

testMain() async {
  debugger();
  print('mmmmm'); // LINE_C.
  await helper(); // LINE_D.
  print('z'); // LINE_E.
}

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  stepOut, // out of helper to awaiter testMain.
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
