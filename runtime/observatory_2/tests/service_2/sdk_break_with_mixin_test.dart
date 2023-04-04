// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_step_test;

import 'dart:collection';
import 'dart:developer';

import 'service_test_common.dart';
import 'test_helper.dart';

int codeRuns = 0;

code() {
  if (++codeRuns > 1) {
    print("Calling debugger!");
    debugger();
  }
  MySet y = new MySet();
  y.forEach((element) {
    print(element);
  });
}

class MySet extends Object with SetMixin {
  bool add(value) => throw UnimplementedError();
  bool contains(Object element) => false;
  Iterator get iterator => [].iterator;
  int get length => 0;
  lookup(Object element) => throw UnimplementedError();
  bool remove(Object value) => throw UnimplementedError();
  Set toSet() => throw UnimplementedError();
}

List<String> stops = [];
List<String> expected = [
  "set.dart:142:21 (sdk_break_with_mixin_test.dart:21:5)",
];

var tests = <IsolateTest>[
  // hasPausedAtStart,
  hasStoppedAtBreakpoint,
  markDartColonLibrariesDebuggable,
  setBreakpointAtUriAndLine(
      "org-dartlang-sdk:///sdk/lib/collection/set.dart", 142),
  resumeProgramRecordingStops(stops, true),
  // runStepIntoThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected, debugPrint: true),
];

main(args) {
  runIsolateTests(args, tests,
      testeeBefore: code,
      testeeConcurrent: code,
      pause_on_start: false,
      pause_on_exit: true);
}
