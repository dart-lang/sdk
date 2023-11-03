// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:async';
import 'dart:developer';

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE_0 = 20;
const int LINE_A = LINE_0 + 1;
const int LINE_B = LINE_A + 3;
const int LINE_C = LINE_B + 1;
const int LINE_D = LINE_C + 2;
const int LINE_E = LINE_D + 1;

testMain() async {
  debugger(); // LINE_0.
  final future1 = Future.value(); // LINE_A.
  final future2 = Future.value();

  await future1; // LINE_B.
  await future2; // LINE_C.

  print('foo1'); // LINE_D.
  print('foo2'); // LINE_E.
}

final tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  smartNext,
  hasStoppedAtBreakpoint,
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  smartNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  resumeIsolate,
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'issue_27238_test.dart',
      testeeConcurrent: testMain,
    );
