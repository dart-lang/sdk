// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 18;
const String file = "next_through_implicit_call_test.dart";

int _fooCallNumber = 0;
foo() {
  ++_fooCallNumber;
  print("Foo call #$_fooCallNumber!");
}

code() {
  foo();
  (foo)();
  var a = [foo];
  a[0]();
  (a[0])();
  var b = [
    [foo, foo]
  ];
  b[0][1]();
  (b[0][1])();
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+0}:3", // on 'foo'
  "$file:${LINE+1}:8", // on '(' (in '()')
  "$file:${LINE+2}:11", // on '['
  "$file:${LINE+3}:4", // on '['
  "$file:${LINE+3}:7", // on '('
  "$file:${LINE+4}:5", // on '['
  "$file:${LINE+4}:9", // on '(' (in '()')
  "$file:${LINE+6}:5", // on '[' (inner one)
  "$file:${LINE+5}:11", // on '[' (outer one)
  "$file:${LINE+8}:4", // on first '['
  "$file:${LINE+8}:7", // on second '['
  "$file:${LINE+8}:10", // on '('
  "$file:${LINE+9}:5", // on first '['
  "$file:${LINE+9}:8", // on second '['
  "$file:${LINE+9}:12", // on '(' (in '()')
  "$file:${LINE+10}:1", // on ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
