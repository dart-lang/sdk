// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_function_2_test.dart";

code() {
  Bar bar = new Bar();
  bar.barXYZ1(42);
  bar.barXYZ2(42);
  fooXYZ1(42);
  fooXYZ2(42);
}

int _xyz = -1;

fooXYZ1(int i) {
  _xyz = i - 1;
}

fooXYZ2(int i) {
  _xyz = i;
}

class Bar {
  int _xyz = -1;

  barXYZ1(int i) {
    _xyz = i - 1;
  }

  barXYZ2(int i) {
    _xyz = i;
  }

  get barXYZ => _xyz + 1;
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // after 'code'
  "$file:${LINE+1}:17", // on 'Bar'

  "$file:${LINE+2}:7", // on 'barXYZ1'
  "$file:${LINE+21}:15", // on 'i'
  "$file:${LINE+22}:14", // on '-'
  "$file:${LINE+22}:5", // on '_xyz'
  "$file:${LINE+23}:3", // on '}'

  "$file:${LINE+3}:7", // on 'barXYZ2'
  "$file:${LINE+25}:15", // on 'i'
  "$file:${LINE+26}:5", // on '_xyz'
  "$file:${LINE+27}:3", // on '}'

  "$file:${LINE+4}:3", // on 'fooXYZ1'
  "$file:${LINE+10}:13", // on 'i'
  "$file:${LINE+11}:12", // on '-'
  "$file:${LINE+12}:1", // on '}'

  "$file:${LINE+5}:3", // on 'fooXYZ2'
  "$file:${LINE+14}:13", // on 'i'
  "$file:${LINE+15}:3", // on '_xyz'
  "$file:${LINE+16}:1", // on '}'

  "$file:${LINE+6}:1" // on ending '}'
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
