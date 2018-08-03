// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 33;
const String file = "step_through_property_get_test.dart";

code() {
  Bar bar = new Bar();
  bar.doStuff();
}

class Foo {
  final List<String> data1;

  Foo() : data1 = ["a", "b", "c"];

  void doStuff() {
    print(data1);
    print(data1[1]);
  }
}

class Bar extends Foo {
  final List<String> data2;

  Bar() : data2 = ["d", "e", "f"];

  void doStuff() {
    print(data2);
    print(data2[1]);

    print(data1);
    print(data1[1]);

    print(super.data1);
    print(super.data1[1]);
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:11", // on 'data2'
  "$file:${LINE+0}:5", // on 'print'
  "$file:${LINE+1}:11", // on 'data2'
  "$file:${LINE+1}:16", // on '['
  "$file:${LINE+1}:5", // on 'print'

  "$file:${LINE+3}:11", // on 'data1'
  "$file:${LINE+3}:5", // on 'print'
  "$file:${LINE+4}:11", // on 'data1'
  "$file:${LINE+4}:16", // on '['
  "$file:${LINE+4}:5", // on 'print'

  "$file:${LINE+6}:17", // on 'data1'
  "$file:${LINE+6}:5", // on 'print'
  "$file:${LINE+7}:17", // on 'data1'
  "$file:${LINE+7}:22", // on '['
  "$file:${LINE+7}:5", // on 'print'

  "$file:${LINE+8}:3" // on ending '}'
];

var tests = <IsolateTest>[
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
