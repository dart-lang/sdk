// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can eliminate object, context and closure
// allocations within try block.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

class A {
  @pragma('vm:prefer-inline')
  void foo() {}
}

class B<T> {
  @pragma('vm:prefer-inline')
  void callMe(void Function() callback) {
    callback();
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int bar() {
  try {
    final a = A();
    final b = B<List<int>>();
    b.callMe(a.foo);
  } finally {
    return 42;
  }
}

void main() {
  Expect.equals(42, bar());
}

void matchIL$bar(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'c_42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      match.Goto('B3', skipUntilMatched: false),
    ]),
    'B3' <<
        match.block('Join', [
          match.Goto('B5', skipUntilMatched: false),
        ]),
    'B5' <<
        match.block('Join', [
          match.DartReturn('c_42'),
        ]),
    'B6' << match.block('CatchBlock'),
  ]);
}
