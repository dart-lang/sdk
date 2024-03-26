// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that inliner can also specialize calls between rounds of inlining.
//
// In the [test] function below we would only be able to fully eliminate
// abstractions and inline [TestIterable.elementAt] if inliner devirtualizes
// it during inlining.

import 'dart:collection';

import 'package:vm/testing/il_matchers.dart';

class TestIterable extends IterableBase<int> {
  @pragma('vm:prefer-inline')
  TestIterator get iterator => TestIterator(this);

  @override
  int get length => 10;

  @pragma('vm:prefer-inline')
  int elementAt(int index) {
    return index;
  }
}

class TestIterator implements Iterator<int> {
  final Iterable<int> iterable;
  int current = 0;
  int index = 0;

  TestIterator(this.iterable);

  @pragma('vm:prefer-inline')
  bool moveNext() {
    if (index >= iterable.length) {
      return false;
    }
    current = iterable.elementAt(index++);
    return true;
  }

  List<int> toList() => [
        for (; moveNext();) current,
      ];
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void test(TestIterable obj) {
  for (var el in obj) {
    print(el);
  }
}

void matchIL$test(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      match.Goto('LoopHeader'),
    ]),
    'LoopHeader' <<
        match.block('Join', [
          'index' << match.Phi(match.any, 'inc'),
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp('index', match.any, kind: '>='),
              ifTrue: 'LoopExit', ifFalse: 'LoopBody'),
        ]),
    'LoopExit' <<
        match.block('Target', [
          match.DartReturn(),
        ]),
    'LoopBody' <<
        match.block('Target', [
          'inc' << match.BinaryInt64Op('index', match.any),
          'boxed_index' << match.BoxInt64('index'),
          'interpolate' << match.StaticCall('boxed_index'),
          match.StaticCall('interpolate'),
          match.Goto('LoopHeader'),
        ]),
  ]);
}

void main() {
  print(TestIterator([0, 1, 2, 3, 4]).toList());
  print(TestIterator(const [0, 1, 2, 3, 4]).toList());
  test(TestIterable());
}
