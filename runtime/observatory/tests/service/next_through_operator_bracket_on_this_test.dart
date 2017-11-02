// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 15;
const String file = "next_through_operator_bracket_on_this_test.dart";

class Class2 {
  operator [](index) => index;

  code() {
    this[42];
    return this[42];
  }
}

code() {
  Class2 c = new Class2();
  c[42];
  c.code();
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:9", // on '['
  "$file:${LINE+1}:16", // on '['
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
