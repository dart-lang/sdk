// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 14;
const String file = "next_through_await_for_test.dart";

code() async {
  int count = 0;
  await for (var num in naturalsTo(2)) {
    print(num);
    count++;
  }
}

Stream<int> naturalsTo(int n) async* {
  int k = 0;
  while (k < n) {
    k++;
    yield k;
  }
  yield 42;
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE + 0}:13", // on '='
  "$file:${LINE + 1}:25", // on 'naturalsTo'

  // Iteration #1
  "$file:${LINE + 1}:3", // on 'await'
  "$file:${LINE + 1}:40", // on '{'
  "$file:${LINE + 2}:5", // on 'print'
  "$file:${LINE + 3}:10", // on '++'

  // Iteration #2
  "$file:${LINE + 1}:3", // on 'await'
  "$file:${LINE + 1}:40", // on '{'
  "$file:${LINE + 2}:5", // on 'print'
  "$file:${LINE + 3}:10", // on '++'

  // Iteration #3
  "$file:${LINE + 1}:3", // on 'await'
  "$file:${LINE + 1}:40", // on '{'
  "$file:${LINE + 2}:5", // on 'print'
  "$file:${LINE + 3}:10", // on '++'

  // Done
  "$file:${LINE + 1}:3", // on 'await'
  "$file:${LINE + 5}:1"
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected,
      debugPrint: true, debugPrintFile: file, debugPrintLine: LINE)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
