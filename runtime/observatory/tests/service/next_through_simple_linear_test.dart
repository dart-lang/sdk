// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'service_test_common.dart';
import 'test_helper.dart';

const int LINE_A = 12;
const String file = "next_through_simple_linear_test.dart";

code() {
  print("Hello, World!"); // LINE_A
  print("Stop here too!");
  print("Goodbye, world!");
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A + 0}:3", // on call to 'print'
  "$file:${LINE_A + 1}:3", // on call to 'print'
  "$file:${LINE_A + 2}:3", // on call to 'print'
  "$file:${LINE_A + 3}:1" // on ending '}'
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
