// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';
import 'dart:collection';

const int LINE = 13;
const String file = "step_through_mixin_from_sdk_test.dart";

code() {
  Foo foo = new Foo();
  if (foo.contains(43)) {
    print("Contains 43!");
  } else {
    print("Doesn't contain 43!");
  }
}

class Foo extends Object with ListMixin<int> {
  @override
  int length = 1;

  @override
  int operator [](int index) {
    return 42;
  }

  @override
  void operator []=(int index, int value) {}
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE + 0}:17", // on "Foo" (in "new Foo()")
  "$file:${LINE + 1}:11", // on "="
  "list.dart:124:25", // on parameter to "contains"
  "list.dart:125:23", // on "length" in "this.length"
  "list.dart:126:16", // on "=" in "i = 0"
  "list.dart:126:23", // on "<" in "i < length"
  "list.dart:127:15", // on "[" in "this[i]"
  "$file:${LINE + 13}:23", // on parameter in "operator []"
  "$file:${LINE + 14}:5", // on "return"
  "list.dart:127:19", // on "=="
  "list.dart:128:26", // on "length" in "this.length"
  "list.dart:128:18", // on "!="
  "list.dart:126:34", // on "++" in "i++"
  "list.dart:126:23", // on "<" in "i < length"
  "list.dart:132:5", // on "return"
  "$file:${LINE + 4}:5", // on "print"
  "$file:${LINE + 6}:1" // on ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepIntoThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected, removeDuplicates: true)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
