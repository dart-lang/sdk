// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'dart:async';
import 'dart:developer';

import 'package:test/test.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_0 = 22;
const int LINE_A = 23;
const int LINE_B = 25;

// This tests the asyncNext command.
asyncFunction() async {
  debugger(); // LINE_0
  print('a'); // LINE_A
  await new Future.delayed(new Duration(seconds: 2));
  print('b'); // LINE_B
}

testMain() {
  asyncFunction();
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_0),
  stepOver,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver, // At new Duration().
  stepOver, // At new Future.delayed().
  stepOver, // At async.
  // Check that we are at the async statement
  (Isolate isolate) async {
    expect(M.isAtAsyncSuspension(isolate.pauseEvent), isTrue);
  },
  asyncNext,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
