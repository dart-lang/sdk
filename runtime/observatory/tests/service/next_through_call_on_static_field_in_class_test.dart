// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE_A = 11;
const String file = "next_through_call_on_static_field_in_class_test.dart";

code() {
  Foo.foo = Foo.fooMethod;
  Foo.fooMethod();
  Foo.foo();
}

class Foo {
  static var foo;

  static void fooMethod() {
    print("Hello from fooMethod");
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE_A+0}:5", // after "code", i.e. on "("
  "$file:${LINE_A+1}:7", // on "foo"
  "$file:${LINE_A+2}:7", // on "fooMethod"
  "$file:${LINE_A+3}:10", // after "foo" (on invisible ".call")
  "$file:${LINE_A+4}:1" // on ending '}'
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
