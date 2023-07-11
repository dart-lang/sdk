// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--async-debugger --verbose-debug

import 'dart:developer';
import 'service_test_common.dart';
import 'test_helper.dart';

const LINE_A = 19;
const LINE_B = 20;
const LINE_C = 25;
const LINE_D = 26;

const LINE_0 = 24;

helper() async {
  print('helper'); // LINE_A.
  print('foobar'); // LINE_B.
}

testMain() {
  debugger(); // LINE_0.
  print('mmmmm'); // LINE_C.
  helper(); // LINE_D.
  print('z');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver, // debugger.

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
  resumeIsolate
];

main(args) => runIsolateTestsSynchronous(args, tests,
    testeeConcurrent: testMain, extraArgs: extraDebuggingArgs);
