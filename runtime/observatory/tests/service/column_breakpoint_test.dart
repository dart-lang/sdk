// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

void testMain() {
  final b = [1, 2].map((i) => i == 0).toList();
  print(b.length);
}

const LINE_A = 9;
const LINE_B = 10;
const String shortFile = "column_breakpoint_test.dart";
const String breakpointFile =
    "package:observatory_test_package/column_breakpoint_test.dart";

List<String> stops = [];

const List<String> expected = [
  '$shortFile:$LINE_A:33', // on first '=' of 'i == 0'
  '$shortFile:$LINE_A:33', // iterate twice
  '$shortFile:$LINE_B:11', // on 'l' of 'b.length'
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLineColumn(LINE_A, 34), // on second '=' of 'i == 0'
  setBreakpointAtLineColumn(LINE_B, 13), // on 'n' of 'b.length'
  resumeProgramRecordingStops(stops, false),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: testMain, pause_on_start: true, pause_on_exit: true);
}
