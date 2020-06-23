// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 13;
const String file = "next_through_call_on_field_test.dart";

var foo;

code() {
  foo = fooMethod;
  fooMethod();
  foo();
}

void fooMethod() {
  print("Hello from fooMethod");
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:5", // after "code", i.e. on "("
  "$file:${LINE_A+1}:3", // on "foo"
  "$file:${LINE_A+2}:3", // on "fooMethod"
  "$file:${LINE_A+3}:6", // after "foo" (on invisible ".call")
  "$file:${LINE_A+4}:1" // on ending '}'
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
