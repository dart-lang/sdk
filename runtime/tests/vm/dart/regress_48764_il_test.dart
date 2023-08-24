// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/48764.
// Verifies that compiler can infer type of captured local variable
// and propagate it to a nested function.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:testing:match-inner-flow-graph', 'testForIn')
void main() {
  var list = [for (var i = 0; i < 100; i += 1) i];

  void testForEach() {
    list.forEach((e) {});
  }

  @pragma('vm:testing:print-flow-graph')
  void testForIn() {
    for (var e in list) {}
  }

  var tests = [
    testForEach,
    testForIn,
  ]..shuffle();

  for (var test in tests) {
    test();
  }
}

void matchIL$main_testForIn(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'v2' << match.Parameter(index: 0),
      'v3' << match.LoadField('v2', slot: 'Closure.context'),
      'v4' << match.LoadField('v3', slot: 'list'),
      'v48' << match.LoadField('v4', slot: ':type_arguments'),
      'v92' << match.LoadField('v4', slot: 'GrowableObjectArray.length'),
      'v112' << match.UnboxInt64('v92'),
      'v107' << match.LoadField('v4', slot: 'GrowableObjectArray.data'),
      match.Goto('B14'),
    ]),
    'B14' <<
        match.block('Join', [
          'v124' << match.Phi(match.any, 'v37'),
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp('v124', 'v112', kind: '>='),
              ifTrue: 'B4', ifFalse: 'B3'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Return(match.any),
        ]),
    'B3' <<
        match.block('Target', [
          match.GenericCheckBound(),
          'v153' << match.LoadIndexed('v107', match.any),
          'v37' << match.BinaryInt64Op('v124', match.any),
          match.Branch(match.StrictCompare('v153', match.any),
              ifTrue: 'B8', ifFalse: 'B9'),
        ]),
    'B8' <<
        match.block('Target', [
          match.AssertAssignable(),
          match.Goto('B10'),
        ]),
    'B9' <<
        match.block('Target', [
          match.Goto('B10'),
        ]),
    'B10' <<
        match.block('Join', [
          match.Goto('B14'),
        ]),
  ]);
}
