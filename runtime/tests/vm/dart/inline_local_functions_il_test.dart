// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can inline local function declared in the outer
// function scope.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
int run(int Function() fn) => fn();

@pragma('vm:testing:match-inner-flow-graph', 'foo')
void main() {
  const int N = 100;
  int id(final int i) => i;

  @pragma('vm:testing:print-flow-graph')
  int foo() {
    int total = 0;
    for (int i = 0; i < N; i++) {
      total += id(i);
    }
    return total;
  }

  final result = run(foo);
  Expect.equals(N * (N - 1) ~/ 2, result);
}

void matchIL$main_foo(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'v2' << match.Parameter(index: 0),
      match.Goto('B5'),
    ]),
    'B5' <<
        match.block('Join', [
          'v5' << match.Phi(match.any, 'v13'),
          'v6' << match.Phi(match.any, 'v15'),
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp('v6', match.any, kind: '<'),
              ifTrue: 'B3', ifFalse: 'B4'),
        ]),
    'B3' <<
        match.block('Target', [
          'v13' << match.BinaryInt64Op('v5', 'v6'),
          'v15' << match.BinaryInt64Op('v6', match.any),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          'v27' << match.BoxInt64('v5'),
          match.Return('v27'),
        ]),
  ]);
}
