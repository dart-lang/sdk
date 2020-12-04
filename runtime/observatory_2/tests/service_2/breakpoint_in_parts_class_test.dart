// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_in_parts_class;

import 'test_helper.dart';
import 'service_test_common.dart';

part 'breakpoint_in_parts_class_part.dart';

const int LINE = 87;
const String file = "breakpoint_in_parts_class_part.dart";

code() {
  Foo10 foo = new Foo10("Foo!");
  print(foo);
}

List<String> stops = [];

List<String> expected = [
  "$file:${LINE+0}:5", // on 'print'
  "$file:${LINE+1}:3" // on class ending '}'
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(file, LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) {
  runIsolateTestsSynchronous(args, tests,
      testeeConcurrent: code, pause_on_start: true, pause_on_exit: true);
}
