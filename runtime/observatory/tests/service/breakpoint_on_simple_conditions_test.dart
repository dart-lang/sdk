// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 15;
const int LINE_B = 18;
const int LINE_C = 20;
const int LINE_D = 22;

testMain() {
  bool foo = false;
  if (foo) {} // ignore:dead_code LINE_A

  const bar = false;
  if (bar) {} // ignore:dead_code LINE_B

  while (foo) {} // ignore:dead_code LINE_C

  while (bar) {} // ignore:dead_code LINE_D
}

var tests = [
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
