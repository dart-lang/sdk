// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.0

import 'dart:math' show pi;
import 'common/service_test_common.dart';
import 'common/test_helper.dart';

const int LINE = 26;
const String FILE = 'step_through_patterns_test.dart';

abstract class Shape {}

class Square implements Shape {
  final double length;
  Square(this.length);
}

class Circle implements Shape {
  final double radius;
  Circle(this.radius);
}

double calculateArea(Shape shape) => switch (shape) {
      Square(length: var l) when l >= 0 => l * l,
      Circle(radius: var r) when r >= 0 => pi * r * r,
      Square(length: var l) when l < 0 => -1,
      Circle(radius: var r) when r < 0 => -1,
      Shape() => 0
    };

testMain() {
  calculateArea(Circle(-123));
}

List<String> stops = [];

List<String> expected = [
  "$FILE:${LINE + 0}:28", // on 'shape' before 'switch'
  "$FILE:${LINE + 1}:7", // on 'Square'
  "$FILE:${LINE + 2}:7", // on 'Circle'
  "$FILE:${LINE + 2}:26", // on 'r' right after 'var'
  "$FILE:${LINE + 2}:36", // on '>='
  "$FILE:${LINE + 3}:7", // on 'Square'
  "$FILE:${LINE + 4}:7", // on 'Circle'
  "$FILE:${LINE + 4}:26", // on 'r' right after 'var'
  "$FILE:${LINE + 4}:36", // on '<'
  "$FILE:${LINE + 4}:40", // on '=>'
  "$FILE:${LINE + 0}:38", // on 'switch'
  "$FILE:36:1", // on closing '}' of [testMain]
];

var tests = <IsolateTest>[
  hasPausedAtStart,
  setBreakpointAtLine(LINE),
  runStepThroughProgramRecordingStops(stops),
  checkRecordedStops(stops, expected)
];

main(args) => runIsolateTestsSynchronous(
      args,
      tests,
      FILE,
      testeeConcurrent: testMain,
      extraArgs: extraDebuggingArgs,
      pause_on_start: true,
      pause_on_exit: true,
    );
