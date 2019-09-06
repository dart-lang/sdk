// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_for_each_sync_star_2_test.dart";

code() {
  for (int datapoint in generator()) {
    print(datapoint);
  }
}

generator() sync* {
  var x = 3;
  var y = 4;
  yield x;
  yield x + y;
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE + 0}:5", // after 'code'
  "$file:${LINE + 1}:25", // on 'generator' (in 'for' line)

  "$file:${LINE + 6}:10", // after 'generator' (definition line)
  "$file:${LINE + 7}:9", // on '=' in 'x = 3'
  "$file:${LINE + 8}:9", // on '=' in 'y = 4'
  "$file:${LINE + 9}:3", // on yield

  "$file:${LINE + 1}:38", // on '{' in 'for' line
  "$file:${LINE + 1}:12", // on 'datapoint'
  "$file:${LINE + 2}:5", // on 'print'
  "$file:${LINE + 1}:25", // on 'generator' (in 'for' line)

  "$file:${LINE + 6}:10", // after 'generator' (definition line)
  "$file:${LINE + 10}:11", // on '+' in 'x + y'
  "$file:${LINE + 10}:3", // on yield

  "$file:${LINE + 1}:38", // on '{' in 'for' line
  "$file:${LINE + 1}:12", // on 'datapoint'
  "$file:${LINE + 2}:5", // on 'print'
  "$file:${LINE + 1}:25", // on 'generator' (in 'for' line)

  "$file:${LINE + 6}:10", // after 'generator' (definition line)
  "$file:${LINE + 11}:1", // on ending '}' of 'generator'

  "$file:${LINE + 4}:1", // on ending '}' of 'code''
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepIntoThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected,
      debugPrint: true, debugPrintFile: file, debugPrintLine: LINE)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
