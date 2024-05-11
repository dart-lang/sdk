// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies fusing of (a & b) == 0 patterns.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
String testValue0(int value) => (value & 1) == 0 ? "f" : "t";

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
String testValue1(int value) => (value & 3) == 0 ? "f" : "t";

final List<String Function(int)> tests = [
  testValue0,
  testValue1,
];

void main() {
  for (var j = 0; j < tests.length; j++) {
    Expect.equals("f", tests[j](0), "mismatch at input 0 test $j");
    Expect.equals("f", tests[j](4), "mismatch at input 4 test $j");
    Expect.equals("t", tests[j](1), "mismatch at input 1 test $j");
    Expect.equals("t", tests[j](3), "mismatch at input 3 test $j");
  }
}

void matchIL$testValue0(FlowGraph graph) {
  if (!isX64 && !isArm64) {
    return;
  }
  graph.match([
    match.block('Graph', [
      'int64(1)' << match.UnboxedConstant(value: 1),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      'unbox(value)' << match.UnboxInt64('value'),
      match.Branch(match.TestInt('unbox(value)', 'int64(1)')),
    ])
  ]);
}

void matchIL$testValue1(FlowGraph graph) {
  if (!isX64 && !isArm64) {
    return;
  }

  graph.match([
    match.block('Graph', [
      'int64(3)' << match.UnboxedConstant(value: 3),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      'unbox(value)' << match.UnboxInt64('value'),
      match.Branch(match.TestInt('unbox(value)', 'int64(3)')),
    ])
  ]);
}
