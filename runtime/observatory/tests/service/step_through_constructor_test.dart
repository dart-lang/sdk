// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 17;
const String file = "step_through_constructor_test.dart";

code() {
  new Foo();
}

class Foo {
  Foo() {
    print("Hello from Foo!");
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // on 'print'
  "$file:${LINE+1}:3", // on ending '}'
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
