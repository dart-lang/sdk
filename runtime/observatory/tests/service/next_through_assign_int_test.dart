// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 12;
const String file = "next_through_assign_int_test.dart";

code() {
  int? a;
  int? b;
  a = b = 42;
  print(a);
  print(b);
  a = 42;
  print(a);
  int? d = 42;
  print(d);
  int? e = 41, f, g = 42;
  print(e);
  print(f);
  print(g);
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:8", // on variable 'a'
  "$file:${LINE_A+1}:8", // on variable 'b'
  "$file:${LINE_A+2}:7", // on 'b'
  "$file:${LINE_A+3}:3", // on call to 'print'
  "$file:${LINE_A+4}:3", // on call to 'print'
  "$file:${LINE_A+5}:3", // on 'a'
  "$file:${LINE_A+6}:3", // on call to 'print'
  "$file:${LINE_A+7}:10", // on '='
  "$file:${LINE_A+8}:3", // on call to 'print'
  "$file:${LINE_A+9}:10", // on first '='
  "$file:${LINE_A+9}:16", // on 'f'
  "$file:${LINE_A+9}:21", // on second '='
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
