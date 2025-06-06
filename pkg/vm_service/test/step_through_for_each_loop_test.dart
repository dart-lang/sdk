// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

// AUTOGENERATED START
//
// Update these constants by running:
//
// dart pkg/vm_service/test/update_line_numbers.dart pkg/vm_service/test/step_through_for_each_loop_test.dart
//
const LINE_A = 20;
// AUTOGENERATED END

const file = 'step_through_for_each_loop_test.dart';

void code() {
  final data = <int>[1, 2, 3, 4]; // LINE_A
  for (final datapoint in data) {
    print(datapoint);
  }
}

final stops = <String>[];
const expected = <String>[
  // Initialize data (on '[')
  '$file:${LINE_A + 0}:21',

  // An iteration of the loop is 'data', '{', then inside loop
  // (on call to 'print')
  '$file:${LINE_A + 1}:27',
  '$file:${LINE_A + 1}:33',
  '$file:${LINE_A + 2}:5',

  // Iteration 2
  '$file:${LINE_A + 1}:27',
  '$file:${LINE_A + 1}:33',
  '$file:${LINE_A + 2}:5',

  // Iteration 3
  '$file:${LINE_A + 1}:27',
  '$file:${LINE_A + 1}:33',
  '$file:${LINE_A + 2}:5',

  // Iteration 4
  '$file:${LINE_A + 1}:27',
  '$file:${LINE_A + 1}:33',
  '$file:${LINE_A + 2}:5',

  // End: Apparently we go to data again, then on the final '}'
  '$file:${LINE_A + 1}:27',
  '$file:${LINE_A + 4}:1',
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE_A),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(
    stops,
    expected,
    debugPrint: true,
    debugPrintFile: file,
    debugPrintLine: LINE_A,
  ),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'step_through_for_each_loop_test.dart',
      testeeConcurrent: code,
      pauseOnStart: true,
      pauseOnExit: true,
    );
