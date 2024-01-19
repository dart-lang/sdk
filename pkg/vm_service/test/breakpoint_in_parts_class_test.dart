// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library breakpoint_in_parts_class;

import 'common/service_test_common.dart';
import 'common/test_helper.dart';

part 'breakpoint_in_parts_class_part.dart';

const int LINE = 88;
const String file = 'breakpoint_in_parts_class_part.dart';

void code() {
  final foo = Foo10('Foo!');
  print(foo);
}

final stops = <String>[];

const expected = <String>[
  '$file:${LINE + 0}:5', // on 'print'
  '$file:${LINE + 1}:3', // on class ending '}'
];

final tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtUriAndLine(file, LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected),
];

void main([args = const <String>[]]) => runIsolateTests(
      args,
      tests,
      'breakpoint_in_parts_class_test.dart',
      testeeConcurrent: code,
      pauseOnStart: true,
      pauseOnExit: true,
    );
