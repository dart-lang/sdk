// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override  --verbose_debug

import 'dart:async';
import 'dart:developer';

import 'test_helper.dart';
import 'service_test_common.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

const int LINE_A = 22;
const int LINE_B = 24;

// This tests the asyncStepOver command.
asyncFunction() async {
  debugger();
  print('a');  // LINE_A
  await new Future.delayed(new Duration(seconds: 2));
  print('b');  // LINE_B
}

testMain() {
  asyncFunction();
}

var tests = [
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  stepOver,  // At new Duration().
  stepOver,  // At new Future.delayed().
  stepOver,  // At async.
  // Check that we are at the async statement
  (Isolate isolate) async {
    expect(M.isAtAsyncSuspension(isolate.pauseEvent), isTrue);
  },
  asyncStepOver,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
