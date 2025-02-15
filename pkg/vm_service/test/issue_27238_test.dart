// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:async';
import 'dart:developer';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart pkg/vm_service/test/issue_27238_test.dart
//
const LINE_0 = 28;
const LINE_A = 29;
const LINE_B = 30;
const LINE_C = 32;
const LINE_D = 33;
const LINE_E = 35;
const LINE_F = 36;
// AUTOGENERATED END

Future<void> testMain() async {
  debugger(); // LINE_0.
  final future1 = Future.value(); // LINE_A.
  final future2 = Future.value(); // LINE_B.

  await future1; // LINE_C.
  await future2; // LINE_D.

  print('foo1'); // LINE_E.
  print('foo2'); // LINE_F.
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLineColumn(line: LINE_A, column: 17), // on '='
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLineColumn(line: LINE_A, column: 26), // on 'value'
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLineColumn(line: LINE_B, column: 17), // on '='
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLineColumn(line: LINE_B, column: 26), // on 'value'
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'issue_27238_test.dart',
      testeeConcurrent: testMain,
    );
