// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler can unbox records in return values.

// SharedOptions=--enable-experiment=records

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
(int, bool) getRecord1(int x, bool y) => (x, y);

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
({String foo, int bar}) getRecord2(String foo, int bar) => (foo: foo, bar: bar);

abstract class A {
  (int, {double y}) get record3;
  Object record4();
}

class B implements A {
  final int x;
  final double y;
  B(this.x, this.y);

  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  (int, {double y}) get record3 => (x, y: y);

  @pragma('vm:never-inline')
  @pragma('vm:testing:print-flow-graph')
  Object record4() => (x, y);
}

class C extends A {
  (int, {double y}) get record3 => (1, y: 2);
  Object record4() => (1, 2);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testSimple(int x, bool z, String foo, int bar, A obj1, A obj2) {
  final r1 = getRecord1(x, z);
  print(r1.$1);
  print(r1.$2);
  final r2 = getRecord2(foo, bar);
  print(r2.foo);
  print(r2.bar);
  final r3 = obj1.record3;
  print(r3.$1);
  print(r3.y);
  final r4 = obj2.record4();
  print(r4);
}

void matchIL$getRecord1(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      'y' << match.Parameter(index: 1),
      'x_boxed' << match.BoxInt64('x'),
      'pair' << match.MakePair('x_boxed', 'y'),
      match.Return('pair'),
    ]),
  ]);
}

void matchIL$getRecord2(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'foo' << match.Parameter(index: 0),
      'bar' << match.Parameter(index: 1),
      'bar_boxed' << match.BoxInt64('bar'),
      'pair' << match.MakePair('bar_boxed', 'foo'),
      match.Return('pair'),
    ]),
  ]);
}

void matchIL$record3(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'this' << match.Parameter(index: 0),
      'x' << match.LoadField('this', slot: 'x'),
      'y' << match.LoadField('this', slot: 'y'),
      'x_boxed' << match.BoxInt64('x'),
      'y_boxed' << match.Box('y'),
      'pair' << match.MakePair('x_boxed', 'y_boxed'),
      match.Return('pair'),
    ]),
  ]);
}

void matchIL$record4(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'this' << match.Parameter(index: 0),
      'x' << match.LoadField('this', slot: 'x'),
      'y' << match.LoadField('this', slot: 'y'),
      'x_boxed' << match.BoxInt64('x'),
      'y_boxed' << match.Box('y'),
      'pair' << match.MakePair('x_boxed', 'y_boxed'),
      match.Return('pair'),
    ]),
  ]);
}

void matchIL$testSimple(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'x' << match.Parameter(index: 0),
      'z' << match.Parameter(index: 1),
      'foo' << match.Parameter(index: 2),
      'bar' << match.Parameter(index: 3),
      'obj1' << match.Parameter(index: 4),
      'obj2' << match.Parameter(index: 5),
      match.CheckStackOverflow(),
      match.MoveArgument('x'),
      match.MoveArgument('z'),
      'r1' << match.StaticCall(),
      'r1_0' << match.ExtractNthOutput('r1', index: 0),
      'r1_1' << match.ExtractNthOutput('r1', index: 1),
      match.MoveArgument('r1_0'),
      match.StaticCall(),
      match.MoveArgument('r1_1'),
      match.StaticCall(),
      match.MoveArgument('foo'),
      match.MoveArgument('bar'),
      'r2' << match.StaticCall(),
      'r2_bar' << match.ExtractNthOutput('r2', index: 0),
      'r2_foo' << match.ExtractNthOutput('r2', index: 1),
      match.MoveArgument('r2_foo'),
      match.StaticCall(),
      match.MoveArgument('r2_bar'),
      match.StaticCall(),
      match.MoveArgument('obj1'),
      'r3' << match.StaticCall(),
      'r3_0' << match.ExtractNthOutput('r3', index: 0),
      'r3_y' << match.ExtractNthOutput('r3', index: 1),
      match.MoveArgument('r3_0'),
      match.StaticCall(),
      match.MoveArgument('r3_y'),
      match.StaticCall(),
      'obj2_cid' << match.LoadClassId('obj2'),
      match.MoveArgument('obj2'),
      'r4' << match.DispatchTableCall('obj2_cid'),
      'r4_0' << match.ExtractNthOutput('r4', index: 0),
      'r4_y' << match.ExtractNthOutput('r4', index: 1),
      'r4_boxed' << match.AllocateSmallRecord('r4_0', 'r4_y'),
      match.MoveArgument('r4_boxed'),
      match.StaticCall(),
      match.Return(),
    ]),
  ]);
}

@pragma('vm:never-inline')
(int, double) getRecord5() => (1 + int.parse('1'), 2.0 + double.parse('2.0'));

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testUnboxedRecordInTryCatch() {
  try {
    final (a, _) = getRecord5();
    print(a);
  } catch (e) {
    print(e);
  }
}

void matchIL$testUnboxedRecordInTryCatch(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.CheckStackOverflow(),
      match.Goto('B1'),
    ]),
    'B1' <<
        match.block('Join', [
          'v1' << match.StaticCall(),
          'v1_a' << match.ExtractNthOutput('v1', index: 0),
          'v1_b' << match.ExtractNthOutput('v1', index: 1),
          'v1_boxed' << match.AllocateSmallRecord('v1_a', 'v1_b'),
          match.MoveArgument('v1_a'),
          match.StaticCall(),
          match.Goto('B3'),
        ]),
    'B2' <<
        match.block('CatchBlock', [
          'e' << match.SpecialParameter(),
          'st' << match.SpecialParameter(),
          match.MoveArgument('e'),
          match.StaticCall(),
          match.Goto('B3'),
        ]),
    'B3' <<
        match.block('Join', [
          match.Return(),
        ]),
  ]);
}

void main(List<String> args) {
  // Make sure all parameters are non-constant
  // and obj1 has a known type for devirtualization.
  final intValue = args.length > 50 ? 1 << 53 : 42;
  final doubleValue = args.length > 50 ? 42.5 : 24.5;

  testSimple(intValue, intValue == 4, 'foo' + intValue.toString(), intValue,
      B(intValue, doubleValue), intValue == 42 ? B(1, 2) : C());

  testUnboxedRecordInTryCatch();
}
