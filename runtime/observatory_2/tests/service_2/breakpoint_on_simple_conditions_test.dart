// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 15;
const int LINE_B = 20;
const int LINE_C = 24;
const int LINE_D = 28;

testMain() {
  bool foo = false;
  if (foo) { // LINE_A
    print('1');
  }

  const bar = false;
  if (bar) { // LINE_B
    print('2');
  }

  while (foo) { // LINE_C
    print('3');
  }

  while (bar) { // LINE_D
    print('4');
  }
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE_A),
  setBreakpointAtLine(LINE_B),
  setBreakpointAtLine(LINE_C),
  setBreakpointAtLine(LINE_D),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests,
    testeeConcurrent: testMain, pause_on_start: true);
