// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 11;
const String file = "step_through_function_test.dart";

code() {
  Bar bar = new Bar();
  print(bar.barXYZ1());
  print(bar.barXYZ2(4, 2));
  print(bar.barXYZ3());
  print(bar.barXYZ4(4, 2));
  print(fooXYZ1());
  print(fooXYZ2(4, 2));
  print(fooXYZ3());
  print(fooXYZ4(4, 2));
}

fooXYZ1 /**/ () => "fooXYZ";
fooXYZ2 /**/ (int i, int j) => "fooXYZ${i}${j}";
fooXYZ3 /**/ () {
  return "fooXYZ";
}

fooXYZ4 /**/ (int i, int j) {
  return "fooXYZ${i}${j}";
}

class Bar {
  barXYZ1 /**/ () => "barXYZ";
  barXYZ2 /**/ (int i, int j) => "barXYZ${i}${j}";
  barXYZ3 /**/ () {
    return "barXYZ";
  }

  barXYZ4 /**/ (int i, int j) {
    return "barXYZ${i}${j}";
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:5", // after 'code'
  "$file:${LINE+1}:17", // on 'Bar'

  "$file:${LINE+2}:13", // on 'barXYZ1'
  "$file:${LINE+23}:16", // after 'barXYZ1', i.e. on '('
  "$file:${LINE+23}:22", // on first '"'
  "$file:${LINE+2}:3", // on 'print'

  "$file:${LINE+3}:13", // on 'barXYZ2'
  "$file:${LINE+24}:28", // on 'j'
  "$file:${LINE+24}:50", // after last '"', i.e. on ';'
  "$file:${LINE+24}:34", // on first '"'
  "$file:${LINE+3}:3", // on 'print'

  "$file:${LINE+4}:13", // on 'barXYZ3'
  "$file:${LINE+25}:16", // after 'barXYZ3', i.e. on '('
  "$file:${LINE+26}:5", // on 'return'
  "$file:${LINE+4}:3", // on 'print'

  "$file:${LINE+5}:13", // on 'barXYZ4'
  "$file:${LINE+29}:28", // on 'j'
  "$file:${LINE+30}:28", // after last '"', i.e. on ';'
  "$file:${LINE+30}:5", // on 'return'
  "$file:${LINE+5}:3", // on 'print'

  "$file:${LINE+6}:9", // on 'fooXYZ1'
  "$file:${LINE+12}:14", // after 'fooXYZ1', i.e. on '('
  "$file:${LINE+12}:20", // on first '"'
  "$file:${LINE+6}:3", // on 'print'

  "$file:${LINE+7}:9", // on 'fooXYZ2'
  "$file:${LINE+13}:26", // on 'j'
  "$file:${LINE+13}:48", // after last '"', i.e. on ';'
  "$file:${LINE+13}:32", // on first '"'
  "$file:${LINE+7}:3", // on 'print'

  "$file:${LINE+8}:9", // on 'fooXYZ3'
  "$file:${LINE+14}:14", // after 'fooXYZ3', i.e. on '('
  "$file:${LINE+15}:3", // on 'return'
  "$file:${LINE+8}:3", // on 'print'

  "$file:${LINE+9}:9", // on 'fooXYZ4'
  "$file:${LINE+18}:26", // on 'j'
  "$file:${LINE+19}:26", // after last '"', i.e. on ';'
  "$file:${LINE+19}:3", // on 'return'
  "$file:${LINE+9}:3", // on 'print'

  "$file:${LINE+10}:1" // on ending '}'
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
