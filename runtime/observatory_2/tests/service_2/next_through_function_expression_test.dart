// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 11;
const String file = "next_through_function_expression_test.dart";

codeXYZ(int i) {
  innerOne() {
    return i * i;
  }

  return innerOne();
}

code() {
  codeXYZ(42);
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:13", // on 'i' in 'codeXYZ(int i)'
  "$file:${LINE_A+1}:3", // on 'innerOne'
  "$file:${LINE_A+5}:18", // on '(', i.e. after 'innerOne' call
  "$file:${LINE_A+5}:3" // on 'return'
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
