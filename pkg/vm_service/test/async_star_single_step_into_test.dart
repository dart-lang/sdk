// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const LINE_A = 17;
const LINE_B = 18;
const LINE_C = 22;
const LINE_D = 26;
const LINE_E = 32;
const LINE_F = 33;

foobar() async* {
  yield 1; // LINE_A.
  yield 2; // LINE_B.
}

helper() async {
  print('helper'); // LINE_C.
  // ignore: unused_local_variable
  await for (var i in foobar()) {
    debugger();
    print('loop'); // LINE_D.
  }
}

testMain() {
  debugger();
  print('mmmmm'); // LINE_E.
  helper(); // LINE_F.
  print('z');
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_E),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_F),
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  // Resume here to exit the generator function.
  // TODO(johnmccutchan): Implement support for step-out of async functions.
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_D),
  stepOver, // print.
  hasStoppedAtBreakpoint,
  stepInto,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  resumeIsolate,
];

main([args = const <String>[]]) =>
    runIsolateTestsSynchronous(args, tests, testeeConcurrent: testMain);
