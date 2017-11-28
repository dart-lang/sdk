// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_step_test;

import 'dart:developer';

import 'mixin_break_class1.dart';
import 'mixin_break_class2.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

const String file = "mixin_break_mixin_class.dart";

int codeRuns = 0;

code() {
  if (++codeRuns > 1) {
    print("Calling debugger!");
    debugger();
  }
  Hello1 a = new Hello1();
  Hello2 b = new Hello2();
  a.speak();
  b.speak();

  print("Both now compiled");
}

List<String> stops = [];
List<String> expected = [
  "$file:5:5 (mixin_break_class1.dart:7:5)",
  "$file:5:5 (mixin_break_class2.dart:7:5)",
];

var tests = [
  hasStoppedAtBreakpoint,
  setBreakpointAtUriAndLine(file, 5),
  resumeProgramRecordingStops(stops, true),
  checkRecordedStops(stops, expected),
];

main(args) {
  runIsolateTests(args, tests,
      testeeBefore: code,
      testeeConcurrent: code,
      pause_on_start: false,
      pause_on_exit: true);
}
