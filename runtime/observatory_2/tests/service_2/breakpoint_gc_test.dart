// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 16;
const int LINE_B = 19;
const int LINE_C = 22;
const String file = "breakpoint_gc_test.dart";

foo() => 42;

testeeMain() {
  foo(); // static call

  dynamic list = [1, 2, 3];
  list.clear(); // instance call
  print(list);

  dynamic local = list; // debug step check = runtime call
  return local;
}

Future forceGC(isolate) async {
  await isolate.invokeRpcNoUpgrade("_collectAllGarbage", {});
}

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(file, LINE_A), // at `foo()`
  setBreakpointAtUriAndLine(file, LINE_B), // at `list.clear()`
  setBreakpointAtUriAndLine(file, LINE_C), // at `local = list`
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_A),
  forceGC, // Should not crash
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_B),
  forceGC, // Should not crash
  resumeIsolate,
  hasStoppedAtBreakpoint,
  stoppedAtLine(LINE_C),
  forceGC, // Should not crash
  resumeIsolate,
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: testeeMain, pause_on_start: true);
}
