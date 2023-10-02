// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/51790.
// Verifies that compiler can recognize int operation in the inlined
// callee when operand is generic.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:prefer-inline')
int add(int a, int b) => a + b;

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int sumAll(List<int> list) {
  int sum = 0;
  for (var e in list) {
    sum = add(sum, e);
  }
  return sum;
}

void main() {
  Expect.equals(6, sumAll(<int>[1, 2, 3]));
  Expect.equals(9, sumAll(<int>[4, 5]));
}

void matchIL$sumAll(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'v2' << match.Parameter(index: 0),
      'v99' << match.LoadField('v2', slot: 'GrowableObjectArray.length'),
      'v120' << match.UnboxInt64('v99'),
      'v114' << match.LoadField('v2', slot: 'GrowableObjectArray.data'),
      match.Goto('B16'),
    ]),
    'B16' <<
        match.block('Join', [
          'v5' << match.Phi(match.any, 'v28'),
          'v130' << match.Phi(match.any, 'v45'),
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp('v130', 'v120', kind: '>='),
              ifTrue: 'B4', ifFalse: 'B3'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Return('v5'),
        ]),
    'B3' <<
        match.block('Target', [
          match.GenericCheckBound(),
          'v135' << match.LoadIndexed('v114', match.any),
          'v45' << match.BinaryInt64Op('v130', match.any),
          'v125' << match.UnboxInt64('v135'),
          'v28' << match.BinaryInt64Op('v5', 'v125'),
          match.Goto('B16'),
        ]),
  ]);
}
