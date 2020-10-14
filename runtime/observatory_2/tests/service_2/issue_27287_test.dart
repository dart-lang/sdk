// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'service_test_common.dart';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 17;
const int LINE_B = 18;

var libVariable;

testMain() {
  debugger();
  print("Before"); // LINE_A
  libVariable = 0; // LINE_B
  print("and after");
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver,
  // Check that debugger stops at assignment to top-level variable.
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
