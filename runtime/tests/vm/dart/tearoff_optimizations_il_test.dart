// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can do CSE and LICM of taking a tear-off.

import 'package:vm/testing/il_matchers.dart';

class A {
  void foo() {}
}

class B<T> {
  Map<T, S>? bar<S>() {
    return null;
  }
}

@pragma('vm:never-inline')
void use(Function func) {
  func();
}

@pragma('vm:never-inline')
void opaqueCall() {}

bool cond = int.parse('1') == 1;

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void testCSE1(A a) {
  use(a.foo);
  if (cond) {
    use(a.foo);
  }
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void testCSE2(B b) {
  use(b.bar);
  if (cond) {
    use(b.bar);
  }
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void testCSE3(B b) {
  use(b.bar<int>);
  if (cond) {
    use(b.bar<num>); // No CSE, please.
  }
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void testLICM1(A a) {
  for (int i = 0; i < 10; ++i) {
    opaqueCall();
    use(a.foo);
  }
}

@pragma('vm:testing:print-flow-graph')
@pragma('vm:never-inline')
void testLICM2(B b) {
  for (int i = 0; i < 10; ++i) {
    opaqueCall();
    use(b.bar);
  }
}

void main() {
  testCSE1(A());
  testCSE2(B());
  testCSE3(B());

  testLICM1(A());
  testLICM2(B());
}

void matchIL$testCSE1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'a' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'a_foo' << match.AllocateClosure(match.any, 'a'),
      match.MoveArgument('a_foo'),
      match.StaticCall(),
      'cond' << match.LoadStaticField(),
      match.Branch(match.StrictCompare('cond', match.any),
          ifTrue: 'B3', ifFalse: 'B4'),
    ]),
    'B3' <<
        match.block('Target', [
          match.MoveArgument('a_foo'),
          match.StaticCall(),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B5' <<
        match.block('Join', [
          match.DartReturn(match.any),
        ]),
  ]);
}

void matchIL$testCSE2(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'b' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'b_type_args' << match.LoadField('b'),
      'b_bar' << match.AllocateClosure(match.any, 'b', 'b_type_args'),
      match.MoveArgument('b_bar'),
      match.StaticCall(),
      'cond' << match.LoadStaticField(),
      match.Branch(match.StrictCompare('cond', match.any),
          ifTrue: 'B3', ifFalse: 'B4'),
    ]),
    'B3' <<
        match.block('Target', [
          match.MoveArgument('b_bar'),
          match.StaticCall(),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B5' <<
        match.block('Join', [
          match.DartReturn(match.any),
        ]),
  ]);
}

void matchIL$testCSE3(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'b' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'b_type_args' << match.LoadField('b'),
      'b_bar' << match.AllocateClosure(match.any, 'b', 'b_type_args'),
      match.MoveArgument('b_bar'),
      match.MoveArgument(match.any),
      match.StaticCall(), // _boundsCheckForPartialInstantiation
      'b_bar_int' << match.AllocateClosure(match.any, 'b', 'b_type_args'),
      match.StoreField('b_bar_int', match.any),
      match.MoveArgument('b_bar_int'),
      match.StaticCall(),
      'cond' << match.LoadStaticField(),
      match.Branch(match.StrictCompare('cond', match.any),
          ifTrue: 'B3', ifFalse: 'B4'),
    ]),
    'B3' <<
        match.block('Target', [
          match.MoveArgument('b_bar'),
          match.MoveArgument(match.any),
          match.StaticCall(), // _boundsCheckForPartialInstantiation
          'b_bar_num' << match.AllocateClosure(match.any, 'b', 'b_type_args'),
          match.StoreField('b_bar_num', match.any),
          match.MoveArgument('b_bar_num'),
          match.StaticCall(),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B5' <<
        match.block('Join', [
          match.DartReturn(match.any),
        ]),
  ]);
}

void matchIL$testLICM1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'a' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'a_foo' << match.AllocateClosure(match.any, 'a'),
      match.Goto('B5'),
    ]),
    'B5' <<
        match.block('Join', [
          'i' << match.Phi(match.any, 'i+1'),
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp('i', match.any),
              ifTrue: 'B3', ifFalse: 'B4'),
        ]),
    'B3' <<
        match.block('Target', [
          match.StaticCall(), // opaqueCall
          match.MoveArgument('a_foo'),
          match.StaticCall(), // use
          'i+1' << match.BinaryInt64Op('i', match.any),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.DartReturn(match.any),
        ]),
  ]);
}

void matchIL$testLICM2(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'b' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'b_type_args' << match.LoadField('b'),
      'b_bar' << match.AllocateClosure(match.any, 'b', 'b_type_args'),
      match.Goto('B5'),
    ]),
    'B5' <<
        match.block('Join', [
          'i' << match.Phi(match.any, 'i+1'),
          match.CheckStackOverflow(),
          match.Branch(match.RelationalOp('i', match.any),
              ifTrue: 'B3', ifFalse: 'B4'),
        ]),
    'B3' <<
        match.block('Target', [
          match.StaticCall(), // opaqueCall
          match.MoveArgument('b_bar'),
          match.StaticCall(), // use
          'i+1' << match.BinaryInt64Op('i', match.any),
          match.Goto('B5'),
        ]),
    'B4' <<
        match.block('Target', [
          match.DartReturn(match.any),
        ]),
  ]);
}
