// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--verbose_debug

import 'test_helper.dart';
import 'dart:developer';
import 'service_test_common.dart';

const int LINE_A = 20;

// :async_op will not be captured in this function because it never needs to
// reschedule it.
asyncWithoutAwait() async {
  print("asyncWithoutAwait");
}

testMain() {
  debugger();
  asyncWithoutAwait(); // Line A.
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  (isolate) => isolate.stepInto(),
  hasStoppedAtBreakpoint,
  (isolate) => isolate.getStack(), // Should not crash.
  // TODO(rmacnak): stoppedAtLine(12)
  // This doesn't happen because asyncWithoutAwait is marked undebuggable.
  // Probably needs to change to support async-step-into.
  resumeIsolate,
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testMain);
