// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.0

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE = 14;
const String file = "breakpoint_on_record_assignment_test.dart";

testMain() {
  (int, String name, bool) triple = (3, 'f', true);
  ({int n, String s}) pair = (n: 2, s: 's');
  (bool, num, {int n, String s}) quad = (false, 3.14, n: 7, s: 'd');
  print('$pair $triple $quad');
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(file, LINE),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE),
  setBreakpointAtUriAndLine(file, LINE + 1),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE + 1),
  setBreakpointAtUriAndLine(file, LINE + 2),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE + 2),
  setBreakpointAtUriAndLine(file, LINE + 3),
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE + 3),
];

main(args) {
  runIsolateTestsSynchronous(
    args,
    tests,
    'breakpoint_on_record_assignment_test.dart',
    testeeConcurrent: testMain,
    pause_on_start: true,
    pause_on_exit: true,
  );
}
