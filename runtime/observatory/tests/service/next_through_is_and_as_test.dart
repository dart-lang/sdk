// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 12;
const String file = "next_through_is_and_as_test.dart";

code() {
  var i = 42.42;
  var hex = 0x42;
  if (i is int) {
    print("i is int");
    int x = i as int;
    if (x.isEven) {
      print("it's even even!");
    } else {
      print("but it's not even even!");
    }
  }
  if (i is! int) {
    print("i is not int");
  }
  if (hex is int) {
    print("hex is int");
    int x = hex as dynamic;
    if (x.isEven) {
      print("it's even even!");
    } else {
      print("but it's not even even!");
    }
  }
  if (hex is! int) {
    print("hex is not int");
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:9", // on '='
  "$file:${LINE_A+1}:11", // on '"'
  "$file:${LINE_A+2}:9", // on 'is'
  "$file:${LINE_A+11}:9", // on 'is!'
  "$file:${LINE_A+12}:5", // on call to 'print'
  "$file:${LINE_A+14}:11", // in 'is'
  "$file:${LINE_A+15}:5", // on call to 'print'
  "$file:${LINE_A+16}:11", // on 'as'
  "$file:${LINE_A+17}:11", // on 'isEven'
  "$file:${LINE_A+18}:7", // on call to 'print'
  "$file:${LINE_A+23}:11", // on 'is!'
  "$file:${LINE_A+26}:1" // on ending '}'
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
