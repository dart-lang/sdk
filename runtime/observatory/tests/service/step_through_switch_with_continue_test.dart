// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_switch_with_continue_test.dart";

code() {
  switch (switchOnMe.length) {
    case 0:
      print("(got 0!");
      continue label;
    label:
    case 1:
      print("Got 0 or 1!");
      break;
    case 2:
      print("Got 2!");
      break;
    default:
      print("Got lost!");
  }
}

List<String> switchOnMe = [];
List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // after 'code'

  "$file:${LINE+1}:11", // on switchOnMe
  "$file:${LINE+1}:22", // on length

  "$file:${LINE+2}:10", // on 0
  "$file:${LINE+3}:7", // on print
  "$file:${LINE+4}:7", // on continue

  "$file:${LINE+7}:7", // on print
  "$file:${LINE+8}:7", // on break

  "$file:${LINE+15}:1" // on ending '}'
];

var tests = [
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
