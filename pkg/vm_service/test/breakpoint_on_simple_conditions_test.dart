// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: dead_code

import 'common/test_helper.dart';
import 'common/service_test_common.dart';

const int LINE_A = 17;
const int LINE_B = 20;
const int LINE_C = 22;
const int LINE_D = 24;

void testMain() {
  bool foo = false;
  if (foo) {} // LINE_A

  const bar = false;
  if (bar) {} // LINE_B

  while (foo) {} // LINE_C

  while (bar) {} // LINE_D
}

final tests = [
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

void main(List<String> args) => runIsolateTests(
      args,
      tests,
      'breakpoint_on_simple_conditions_test.dart',
      testeeConcurrent: testMain,
      pause_on_start: true,
    );
