// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 12;
const String file = "next_through_for_each_loop_test.dart";

code() {
  List<int> data = [1, 2, 3, 4];
  for (int datapoint in data) {
    print(datapoint);
  }
}

List<String> stops = [];
List<String> expected = [
  // Initialize data (on '[')
  "$file:${LINE+0}:20",

  // An iteration of the loop is "data", "{", then inside loop
  // (on call to 'print')
  "$file:${LINE+1}:25",
  "$file:${LINE+1}:31",
  "$file:${LINE+2}:5",

  // Iteration 2
  "$file:${LINE+1}:25",
  "$file:${LINE+1}:31",
  "$file:${LINE+2}:5",

  // Iteration 3
  "$file:${LINE+1}:25",
  "$file:${LINE+1}:31",
  "$file:${LINE+2}:5",

  // Iteration 4
  "$file:${LINE+1}:25",
  "$file:${LINE+1}:31",
  "$file:${LINE+2}:5",

  // End: Apparently we go to data again, then on the final "}"
  "$file:${LINE+1}:25",
  "$file:${LINE+4}:1"
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected,
      debugPrint: true, debugPrintFile: file, debugPrintLine: LINE)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
