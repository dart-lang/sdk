// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_arithmetic_test.dart";

code() {
  print(1 + 2);
  print((1 + 2) / 2);
  print(1 + 2 * 3);
  print((1 + 2) * 3);
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // after 'code'

  "$file:${LINE+1}:11", // on '+'
  "$file:${LINE+1}:3", // on 'print'

  "$file:${LINE+2}:12", // on '+'
  "$file:${LINE+2}:17", // on '/'
  "$file:${LINE+2}:3", // on 'print'

  "$file:${LINE+3}:15", // on '*'
  "$file:${LINE+3}:11", // on '+'
  "$file:${LINE+3}:3", // on 'print'

  "$file:${LINE+4}:12", // on '+'
  "$file:${LINE+4}:17", // on '*'
  "$file:${LINE+4}:3", // on 'print'

  "$file:${LINE+5}:1" // on ending '}'
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
