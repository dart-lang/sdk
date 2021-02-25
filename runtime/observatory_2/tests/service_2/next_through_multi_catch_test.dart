// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'test_helper.dart';
import 'service_test_common.dart';

const int LINE = 12;
const String file = "next_through_multi_catch_test.dart";

code() {
  try {
    throw "Boom!";
  } on StateError {
    print("StateError");
  } on ArgumentError catch (e) {
    print("ArgumentError: $e");
  } catch (e) {
    print(e);
  }
}

List<String> stops = [];
List<String> expected = [
  "$file:${LINE+1}:5", // on 'throw'
  "$file:${LINE+2}:5", // on 'on'
  "$file:${LINE+4}:5", // on 'on'
  "$file:${LINE+7}:5", // on 'print'
  "$file:${LINE+9}:1", // on ending '}'
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
