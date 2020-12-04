// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--lazy-async-stacks

import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:io';

const int LINE_A = 14;
const String file = "next_through_simple_async_with_returns_test.dart";

code() async {  // LINE_A
  File f = new File(Platform.script.toFilePath());
  bool exists = await f.exists();
  if (exists) {
    return 42;
  }
  foo();
}

foo() {
  print("Hello from Foo!");
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:5", // on '(' in 'code()'
  "$file:${LINE_A+1}:30", // on 'script'
  "$file:${LINE_A+1}:37", // on 'toFilePath'
  "$file:${LINE_A+1}:16", // on 'File'
  "$file:${LINE_A+2}:25", // on 'exists'
  "$file:${LINE_A+2}:17", // on 'await'
  "$file:${LINE_A+4}:5" // on 'return'
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
