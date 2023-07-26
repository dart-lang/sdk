// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

void testMain() {
  var b = [1, 2].map((i) => i == 0).toList();
  print(b.length);
}

const int LINE = 9;
const int COLUMN = 29;
const String shortFile = "column_breakpoint_test.dart";
const String breakpointFile =
    "package:observatory_test_package_2/column_breakpoint_test.dart";

List<String> stops = [];

const List<String> expected = [
  "$shortFile:${LINE + 0}:29", // on 'i == 0'
  "$shortFile:${LINE + 0}:29", // iterate twice
  "$shortFile:${LINE + 1}:11" //on 'b.length'
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLineColumn(LINE, COLUMN), // on 'i == 0'
  setBreakpointAtLineColumn(LINE + 1, 9), // on 'b.length'
  resumeProgramRecordingStops(stops, false),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: testMain, pause_on_start: true, pause_on_exit: true);
}
