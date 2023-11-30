// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:developer';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_0 = 18;
const int LINE_A = LINE_0 + 1;
const int LINE_B = LINE_A + 1;

late int libVariable;

void testMain() {
  debugger(); // LINE_0
  print('Before'); // LINE_A
  libVariable = 0; // LINE_B
  print('and after');
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver,
  // Check that debugger stops at assignment to top-level variable.
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'issue_27287_test.dart',
      testeeConcurrent: testMain,
    );
