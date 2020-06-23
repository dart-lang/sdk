// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 14;
const String file = "next_through_closure_test.dart";

codeXYZ(int i) {
  var x = () =>
      // some comment here to allow this formatting
      i * i; // LINE_A
  return x();
}

code() {
  codeXYZ(42);
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:9", // on '*'
  "$file:${LINE_A+0}:7", // on first 'i'
  "$file:${LINE_A+1}:3", // on 'return'
  "$file:${LINE_A+6}:1" // on ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE_A),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
