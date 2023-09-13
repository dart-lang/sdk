// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Given
//
//    Branch if StrictCompare(v === Constant(C)) then B1 else B2
//
// constant propagation should treat all uses of `v` dominated by
// B1 as if they were equal to C.
//
// The same applies to the negated case, where `v` is equal to `C`
// in the false successor. The same applies to EqualityCompare() when applied
// to integers.
//
// Note that we don't want to actually eagerly replace `v` with `C` because
// it might complicate subsequent optimizations by introducing redundant phis.

import 'package:vm/testing/il_matchers.dart';

class A {
  final int v;
  const A(this.v);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int strictCompareValueEqConstant(A value) {
  if (value == const A(0)) {
    return value.v;
  } else {
    return 42;
  }
}

void matchIL$strictCompareValueEqConstant(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'A(0)' << match.Constant(value: "Instance of A"),
      'int 0' << match.UnboxedConstant(value: 0),
      'int 42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.StrictCompare('value', 'A(0)', kind: '==='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('int 0'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('int 42'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int strictCompareConstantEqValue(A value) {
  if (const A(0) == value) {
    return value.v;
  } else {
    return 42;
  }
}

void matchIL$strictCompareConstantEqValue(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'A(0)' << match.Constant(value: "Instance of A"),
      'int 0' << match.UnboxedConstant(value: 0),
      'int 42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.StrictCompare('A(0)', 'value', kind: '==='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('int 0'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('int 42'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int strictCompareValueNeConstant(A value) {
  if (value != const A(0)) {
    return 42;
  } else {
    return value.v;
  }
}

void matchIL$strictCompareValueNeConstant(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'A(0)' << match.Constant(value: "Instance of A"),
      'int 0' << match.UnboxedConstant(value: 0),
      'int 42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.StrictCompare('value', 'A(0)', kind: '!=='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('int 42'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('int 0'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int strictCompareConstantNeValue(A value) {
  if (const A(0) != value) {
    return 42;
  } else {
    return value.v;
  }
}

void matchIL$strictCompareConstantNeValue(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'A(0)' << match.Constant(value: "Instance of A"),
      'int 0' << match.UnboxedConstant(value: 0),
      'int 42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.StrictCompare('A(0)', 'value', kind: '!=='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('int 42'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('int 0'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool strictCompareBoolEqTrue(bool value) {
  // Note: expect false to be propagated into the false successor as well.
  if (value == true) {
    return !value;
  } else {
    return !value;
  }
}

void matchIL$strictCompareBoolEqTrue(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'true' << match.Constant(value: true),
      'false' << match.Constant(value: false),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.StrictCompare('value', 'true', kind: '==='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('false'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('true'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
bool strictCompareBoolNeTrue(bool value) {
  // Note: expect false to be propagated into the true successor as well.
  if (value != true) {
    return !value;
  } else {
    return !value;
  }
}

void matchIL$strictCompareBoolNeTrue(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'true' << match.Constant(value: true),
      'false' << match.Constant(value: false),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.StrictCompare('value', 'true', kind: '!=='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('true'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('false'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int equalityCompareValueEqConstant(int value) {
  if (value == 0) {
    return value + 1;
  } else {
    return 42;
  }
}

void matchIL$equalityCompareValueEqConstant(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'int 0' << match.UnboxedConstant(value: 0),
      'int 1' << match.UnboxedConstant(value: 1),
      'int 42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.EqualityCompare('value', 'int 0', kind: '=='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('int 1'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('int 42'),
        ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int foldingOfRepeatedComparison(int value) {
  final v = value >= 1;
  if (v) {
    if (v) {
      return 1;
    } else {
      return 24;
    }
  } else {
    return 42;
  }
}

void matchIL$foldingOfRepeatedComparison(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'int 1' << match.UnboxedConstant(value: 1),
      'int 42' << match.UnboxedConstant(value: 42),
    ]),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      match.Branch(match.RelationalOp('value', 'int 1', kind: '>='),
          ifTrue: 'B1', ifFalse: 'B2'),
    ]),
    'B1' <<
        match.block('Target', [
          match.Return('int 1'),
        ]),
    'B2' <<
        match.block('Target', [
          match.Return('int 42'),
        ]),
  ]);
}

void main(List<String> args) {
  for (var v in [
    A(0),
    A(1),
    A(42),
    A(int.parse(args.isEmpty ? "24" : args[0])),
  ]) {
    print(strictCompareValueEqConstant(v));
    print(strictCompareConstantEqValue(v));
    print(strictCompareValueNeConstant(v));
    print(strictCompareConstantNeValue(v));
    print(equalityCompareValueEqConstant(v.v));
    print(foldingOfRepeatedComparison(v.v));
  }

  for (var v in [true, false]) {
    print(strictCompareBoolEqTrue(v));
    print(strictCompareBoolNeTrue(v));
  }
}
