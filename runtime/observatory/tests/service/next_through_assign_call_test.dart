// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 12;
const String file = "next_through_assign_call_test.dart";

code() {
  int? a;
  int? b;
  a = b = foo();
  print(a);
  print(b);
  a = foo();
  print(a);
  int? d = foo();
  print(d);
  int? e = foo(), f, g = foo();
  print(e);
  print(f);
  print(g);
}

foo() {
  return 42;
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:8", // on variable 'a'
  "$file:${LINE_A+1}:8", // on variable 'b'
  "$file:${LINE_A+2}:11", // on call to 'foo'
  "$file:${LINE_A+3}:3", // on call to 'print'
  "$file:${LINE_A+4}:3", // on call to 'print'
  "$file:${LINE_A+5}:7", // on call to 'foo'
  "$file:${LINE_A+6}:3", // on call to 'print'
  "$file:${LINE_A+7}:12", // on call to 'foo'
  "$file:${LINE_A+8}:3", // on call to 'print'
  "$file:${LINE_A+9}:12", // on first call to 'foo'
  "$file:${LINE_A+9}:19", // on variable 'f'
  "$file:${LINE_A+9}:26", // on second call to 'foo'
  "$file:${LINE_A+10}:3", // on call to 'print'
  "$file:${LINE_A+11}:3", // on call to 'print'
  "$file:${LINE_A+12}:3", // on call to 'print'
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
