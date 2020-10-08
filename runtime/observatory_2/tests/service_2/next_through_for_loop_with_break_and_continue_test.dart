// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 12;
const String file = "next_through_for_loop_with_break_and_continue_test.dart";

code() {
  int count = 0;
  for (int i = 0; i < 42; ++i) {
    if (i == 2) {
      continue;
    }
    if (i == 3) {
      break;
    }
    count++;
  }
  print(count);
}

List<String> stops = [];
List<String> expected = [
  // Initialization (on '='), loop start (on '='),
  // first iteration (on '<', on '==', on '==', on '++')
  "$file:${LINE_A+0}:13",
  "$file:${LINE_A+1}:14",
  "$file:${LINE_A+1}:21",
  "$file:${LINE_A+2}:11",
  "$file:${LINE_A+5}:11",
  "$file:${LINE_A+8}:10",

  // Second iteration of loop: Full run
  // (on '++', on '<', on '==', on '==', on '++')
  "$file:${LINE_A+1}:27",
  "$file:${LINE_A+1}:21",
  "$file:${LINE_A+2}:11",
  "$file:${LINE_A+5}:11",
  "$file:${LINE_A+8}:10",

  // Third iteration of loop: continue
  // (on '++', on '<', on '==', on 'continue')
  "$file:${LINE_A+1}:27",
  "$file:${LINE_A+1}:21",
  "$file:${LINE_A+2}:11",
  "$file:${LINE_A+3}:7",

  // Forth iteration of loop: break
  // (on '++', on '<', on '==' on '==', on 'break')
  "$file:${LINE_A+1}:27",
  "$file:${LINE_A+1}:21",
  "$file:${LINE_A+2}:11",
  "$file:${LINE_A+5}:11",
  "$file:${LINE_A+6}:7",

  // End (on call to 'print' and on ending '}')
  "$file:${LINE_A+10}:3",
  "$file:${LINE_A+11}:1"
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
