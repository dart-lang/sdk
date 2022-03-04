// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

// This test creates a phi which has multiple inputs referring to the same
// AllocateObject instruction. When delaying this allocation we need to
// look at all of these inputs and not just at the first one.

bool shouldPrint = false;

@pragma('vm:never-inline')
void blackhole(Object v) {
  if (shouldPrint) {
    print(v);
  }
}

class X {
  dynamic field;

  @override
  String toString() => 'X($field)';
}

// This function is used to create a phi with three arguments two of which
// point to the same definition: original value of [v].
@pragma('vm:prefer-inline')
X decisionTree(bool a, bool b, X v) {
  if (a) {
    v.field = 10;
    blackhole(v);
    return v;
  } else if (b) {
    return v;
  } else {
    return X();
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
dynamic testDelayAllocationsUnsunk(bool a, bool b) {
  // Allocation is expected to be unsunk because no use dominates all other
  // uses.
  var v = X();
  if (a) {
    blackhole(b);
  }
  v = decisionTree(a, b, v);
  blackhole(v);
  return v.field;
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
dynamic testDelayAllocationsSunk(bool a, bool b) {
  var v = X();
  if (a) {
    blackhole(b);
  }
  v.field = 42; // Allocation is expected to be sunk past if to this use.
  v = decisionTree(a, b, v);
  blackhole(v);
  return v.field;
}

List<dynamic> testAllVariants(dynamic Function(bool, bool) f) {
  return [
    for (var a in [true, false])
      for (var b in [true, false]) f(a, b),
  ];
}

void main(List<String> args) {
  shouldPrint = args.contains("shouldPrint");

  Expect.listEquals(
      [10, 10, null, null], testAllVariants(testDelayAllocationsUnsunk));
  Expect.listEquals(
      [10, 10, 42, null], testAllVariants(testDelayAllocationsSunk));
}

void matchIL$testDelayAllocationsUnsunk(FlowGraph afterDelayAllocations) {
  afterDelayAllocations.dump();
  afterDelayAllocations.match([
    match.block('Graph'),
    match.block('Function', [
      // Allocation must stay unsunk
      match.AllocateObject()
    ])
  ]);
}

void matchIL$testDelayAllocationsSunk(FlowGraph afterDelayAllocations) {
  afterDelayAllocations.dump();
  afterDelayAllocations.match([
    match.block('Graph'),
    match.block('Function', [
      // Allocation must be sunk from this block.
      match.Branch(match.StrictCompare(match.any, match.any, kind: '==='),
          ifTrue: 'B3', ifFalse: 'B4'),
    ]),
    'B3' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B5' <<
        match.block('Join', [
          match.AllocateObject(),
        ]),
  ]);
}
