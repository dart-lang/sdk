// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 22;
const String file = "next_through_operator_bracket_on_super_test.dart";

class Class2 {
  operator [](index) => index;

  code() {
    this[42];
    return this[42];
  }
}

class Class3 extends Class2 {
  code() {
    super[42];
    return super[42];
  }
}

code() {
  Class3 c = new Class3();
  c[42];
  c.code();
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:10", // on '['
  "$file:${LINE+1}:17", // on '['
  "$file:${LINE+1}:5", // on 'return'
];

var tests = [
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
