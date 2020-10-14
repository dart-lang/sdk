// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_switch_test.dart";

code() {
  code2('a');
  code2('b');
  code2('c');
  code2('d');
}

code2(String key) {
  switch (key) {
    case "a":
      print("a!");
      break;
    case "b":
    case "c":
      print("b or c!");
      break;
    default:
      print("neither a, b or c...");
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // after 'code'

  "$file:${LINE+1}:3", // on 'code2'
  "$file:${LINE+7}:14", // on 'key'
  "$file:${LINE+9}:10", // on first '"' on 'case "a"' line
  "$file:${LINE+10}:7", // on 'print'
  "$file:${LINE+11}:7", // on 'break'
  "$file:${LINE+19}:1", // on '}'

  "$file:${LINE+2}:3", // on 'code2'
  "$file:${LINE+7}:14", // on 'key'
  "$file:${LINE+9}:10", // on first '"' on 'case "a"' line
  "$file:${LINE+12}:10", // on first '"' on 'case "b"' line
  "$file:${LINE+14}:7", // on 'print'
  "$file:${LINE+15}:7", // on 'break'
  "$file:${LINE+19}:1", // on '}'

  "$file:${LINE+3}:3", // on 'code2'
  "$file:${LINE+7}:14", // on 'key'
  "$file:${LINE+9}:10", // on first '"' on 'case "a"' line
  "$file:${LINE+12}:10", // on first '"' on 'case "b"' line
  "$file:${LINE+13}:10", // on first '"' on 'case "c"' line
  "$file:${LINE+14}:7", // on 'print'
  "$file:${LINE+15}:7", // on 'break'
  "$file:${LINE+19}:1", // on '}'

  "$file:${LINE+4}:3", // on 'code2'
  "$file:${LINE+7}:14", // on 'key'
  "$file:${LINE+9}:10", // on first '"' on 'case "a"' line
  "$file:${LINE+12}:10", // on first '"' on 'case "b"' line
  "$file:${LINE+13}:10", // on first '"' on 'case "c"' line
  "$file:${LINE+17}:7", // on 'print'
  "$file:${LINE+19}:1", // on '}'

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
