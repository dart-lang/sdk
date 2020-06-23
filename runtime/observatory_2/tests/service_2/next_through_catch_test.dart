// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 12;
const String file = "next_through_catch_test.dart";

code() {
  try {
    var value = "world";
    throw "Hello, $value";
  } catch (e, st) {
    print(e);
    print(st);
  }
  try {
    throw "Hello, world";
  } catch (e, st) {
    print(e);
    print(st);
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+1}:15", // on '='
  "$file:${LINE_A+2}:26", // after last '"' (i.e. before ';')
  "$file:${LINE_A+4}:5", // on call to 'print'
  "$file:${LINE_A+5}:5", // on call to 'print'
  "$file:${LINE_A+8}:5", // on 'throw'
  "$file:${LINE_A+10}:5", // on call to 'print'
  "$file:${LINE_A+11}:5", // on call to 'print'
  "$file:${LINE_A+13}:1" // on ending '}'
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
