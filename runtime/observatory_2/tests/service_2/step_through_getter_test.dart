// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_getter_test.dart";

code() {
  Bar bar = new Bar();
  print(bar.barXYZ);
  print(bar.barXYZ2);
  print(fooXYZ);
  print(fooXYZ2);
}

get fooXYZ => "fooXYZ";

get fooXYZ2 {
  int i = 42;
  return "Hello, $i!";
}

class Bar {
  get barXYZ => "barXYZ";

  get barXYZ2 {
    int i = 42;
    return "Hello, $i!";
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // after 'code'
  "$file:${LINE+1}:17", // on 'Bar'

  "$file:${LINE+2}:13", // on 'barXYZ'
  "$file:${LINE+16}:14", // on '=>' in 'get barXYZ => "barXYZ";'
  "$file:${LINE+16}:17", // on first '"'
  "$file:${LINE+2}:3", // on 'print'

  "$file:${LINE+3}:13", // on 'barXYZ2'
  "$file:${LINE+18}:15", // on '{' in 'get barXYZ2 {'
  "$file:${LINE+19}:11", // on '='
  "$file:${LINE+20}:24", // after '"', i.e. on ';'
  "$file:${LINE+20}:5", // on 'return'
  "$file:${LINE+3}:3", // on 'print'

  "$file:${LINE+4}:9", // on 'fooXYZ'
  "$file:${LINE+8}:12", // on '=>' in 'get fooXYZ => "fooXYZ";'
  "$file:${LINE+8}:15", // on first '"'
  "$file:${LINE+4}:3", // on 'print'

  "$file:${LINE+5}:9", // on 'fooXYZ2'
  "$file:${LINE+10}:13", // on '{'
  "$file:${LINE+11}:9", // on '='
  "$file:${LINE+12}:22", // after '"', i.e. on ';'
  "$file:${LINE+12}:3", // on 'return'
  "$file:${LINE+5}:3", // on 'print'

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
