// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 12;
const String file = "next_through_create_list_and_map_test.dart";

code() {
  List<int> myList = [
    1234567890,
    1234567891,
    1234567892,
    1234567893,
    1234567894
  ];
  List<int> myConstList = const [
    1234567890,
    1234567891,
    1234567892,
    1234567893,
    1234567894
  ];
  Map<int, int> myMap = {
    1: 42,
    2: 43,
    33242344: 432432432,
    443243232: 543242454
  };
  Map<int, int> myConstMap = const {
    1: 42,
    2: 43,
    33242344: 432432432,
    443243232: 543242454
  };
  print(myList);
  print(myConstList);
  int lookup = myMap[1];
  print(lookup);
  print(myMap);
  print(myConstMap);
  print(myMap[2]);
}

List<String> stops = [];
List<String> expected = [
  // Initialize list (on '[')
  "$file:${LINE_A+0}:22",

  // Initialize const list (on '=')
  "$file:${LINE_A+7}:25",

  // Initialize map (on '{')
  "$file:${LINE_A+14}:25",

  // Initialize const map (on '=')
  "$file:${LINE_A+20}:28",

  // Prints (on call to 'print')
  "$file:${LINE_A+26}:3",
  "$file:${LINE_A+27}:3",

  // Lookup (on '[')
  "$file:${LINE_A+28}:21",

  // Prints (on call to 'print')
  "$file:${LINE_A+29}:3",
  "$file:${LINE_A+30}:3",
  "$file:${LINE_A+31}:3",

  // Lookup (on '[') + print (on call to 'print')
  "$file:${LINE_A+32}:14",
  "$file:${LINE_A+32}:3",

  // End (on ending '}')
  "$file:${LINE_A+33}:1"
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
