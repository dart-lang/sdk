// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'service_test_common.dart';
import 'dart:async';
import 'test_helper.dart';
import 'dart:developer';

const int LINE_A = 21;
const int LINE_B = 24;
const int LINE_C = 25;
const int LINE_D = 27;
const int LINE_E = 28;

const int LINE_0 = 20;

testMain() async {
  debugger(); // LINE_0.
  Future future1 = new Future.value(); // LINE_A.
  Future future2 = new Future.value();

  await future1; // LINE_B.
  await future2; // LINE_C.

  print('foo1'); // LINE_D.
  print('foo2'); // LINE_E.
}

var tests = <IsolateTest>[
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

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
