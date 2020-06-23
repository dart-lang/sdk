// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 11;
const String file = "next_through_new_test.dart";

code() {
  var x = new Foo();
  return x;
}

class Foo {
  var x;
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:5", // on '(' in 'code()'
  "$file:${LINE_A+1}:15", // on 'Foo'
  "$file:${LINE_A+2}:3" // on 'return'
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
