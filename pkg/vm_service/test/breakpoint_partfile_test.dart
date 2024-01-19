// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_in_parts_class;

import 'package:test_package/has_part.dart' as has_part;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE = 9;
const String breakpointFile = 'package:test_package/the_part_2.dart';
const String shortFile = 'the_part_2.dart';

void code() {
  has_part.bar();
}

final stops = <String>[];

const expected = <String>[
  '$shortFile:${LINE + 0}:3', // on 'print'
  '$shortFile:${LINE + 1}:1', // on class ending '}'
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(breakpointFile, LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'breakpoint_partfile_test.dart',
      testeeConcurrent: code,
      pauseOnStart: true,
      pauseOnExit: true,
    );
