// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for @pragma('dyn-module:extendable') and @pragma('dyn-module:can-be-overridden').

import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
void myprint(Object message) {
  print(message);
}

abstract class A1 {
  void foo();
  void bar();
  void baz();
}

class B1 extends A1 {
  void foo() {
    myprint('B1.foo');
  }

  void bar() {
    myprint('B1.bar');
  }

  @pragma('vm:never-inline')
  void baz() {
    myprint('B1.baz');
  }
}

class C1 extends B1 {
  @pragma('vm:never-inline')
  void baz() {
    myprint('C1.baz');
  }
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void callA1(A1 obj) {
  obj.foo();
  obj.bar();
  obj.baz();
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testIsA1(obj) {
  myprint(obj is A1);
  myprint(obj is B1);
  myprint(obj is C1);
}

@pragma('dyn-module:implicitly-extendable')
abstract class A2 {
  void foo();
  @pragma('dyn-module:can-be-overridden-implicitly')
  void bar();
  void baz();
}

@pragma('dyn-module:extendable')
class B2 extends A2 {
  void foo() {
    myprint('B2.foo');
  }

  @pragma('dyn-module:can-be-overridden')
  void bar() {
    myprint('B2.bar');
  }

  @pragma('vm:never-inline')
  void baz() {
    myprint('B2.baz');
  }
}

class C2 extends B2 {
  @pragma('vm:never-inline')
  void baz() {
    myprint('C2.baz');
  }
}

class D2 extends B2 {}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void callA2(A2 obj) {
  obj.foo();
  obj.bar();
  obj.baz();
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testIsA2(obj) {
  myprint(obj is A2);
  myprint(obj is B2);
  myprint(obj is C2);
}

List objs = [Object(), B1(), C1(), B2(), C2()];

main() {
  for (final obj in objs) {
    testIsA1(obj);
    testIsA2(obj);
    if (obj is A1) {
      callA1(obj);
    }
    if (obj is A2) {
      callA2(obj);
    }
  }
  testCallInTryWithControlFlow(getMyString(), int.parse('1'));
}

void matchIL$callA1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      match.MoveArgument(match.any),
      match.StaticCall(match.any),
      match.MoveArgument(match.any),
      match.StaticCall(match.any),
      'cid' << match.LoadClassId('obj'),
      match.MoveArgument('obj'),
      match.DispatchTableCall('cid'),
      match.DartReturn(match.any),
    ]),
  ]);
}

void matchIL$callA2(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      match.MoveArgument(match.any),
      match.StaticCall(match.any),
      'cid1' << match.LoadClassId('obj'),
      match.Branch(match.TestRange('cid1'), ifTrue: 'B7', ifFalse: 'B8'),
    ]),
    'B7' <<
        match.block('Target', [
          match.MoveArgument('obj'),
          match.DispatchTableCall('cid1'),
          match.Goto('B9'),
        ]),
    'B8' <<
        match.block('Target', [
          match.MoveArgument('obj'),
          match.InstanceCall('obj'),
          match.Goto('B9'),
        ]),
    'B9' <<
        match.block('Join', [
          'cid2' << match.LoadClassId('obj'),
          match.Branch(match.TestRange('cid2'), ifTrue: 'B10', ifFalse: 'B11'),
        ]),
    'B10' <<
        match.block('Target', [
          match.MoveArgument('obj'),
          match.DispatchTableCall('cid2'),
          match.Goto('B12'),
        ]),
    'B11' <<
        match.block('Target', [
          match.MoveArgument('obj'),
          match.InstanceCall('obj'),
          match.Goto('B12'),
        ]),
    'B12' <<
        match.block('Join', [
          match.DartReturn(match.any),
        ]),
  ]);
}

void matchIL$testIsA1(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'cid' << match.LoadClassId('obj'),
      'test1' << match.TestRange('cid'),
      match.MoveArgument('test1'),
      match.StaticCall('test1'),
      match.MoveArgument('test1'),
      match.StaticCall('test1'),
      'test2' << match.EqualityCompare('cid', match.any, kind: '=='),
      match.MoveArgument('test2'),
      match.StaticCall('test2'),
      match.DartReturn(match.any),
    ]),
  ]);
}

void matchIL$testIsA2(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'obj' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'test1' << match.InstanceOf('obj', match.any, match.any),
      match.MoveArgument('test1'),
      match.StaticCall('test1'),
      'test2' << match.InstanceOf('obj', match.any, match.any),
      match.MoveArgument('test2'),
      match.StaticCall('test2'),
      'cid' << match.LoadClassId('obj'),
      'test3' << match.EqualityCompare('cid', match.any, kind: '=='),
      match.MoveArgument('test3'),
      match.StaticCall('test3'),
      match.DartReturn(match.any),
    ]),
  ]);
}

@pragma('dyn-module:extendable')
class MyString {
  @pragma('dyn-module:can-be-overridden')
  @pragma('vm:never-inline')
  int get length => int.parse('2');

  @pragma('dyn-module:can-be-overridden')
  @pragma('vm:never-inline')
  String substring(int start) => 42.toString();
}

MyString getMyString() => [MyString()][int.parse('0')];

@pragma('vm:never-inline')
int intParse(String str) => int.parse(str);

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void testCallInTryWithControlFlow(MyString value, int pos) {
  if (pos == value.length) {
  } else {
    try {
      intParse(value.substring(pos));
    } catch (e) {}
  }
}

void matchIL$testCallInTryWithControlFlow(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', []),
    match.block('Function', [
      'value' << match.Parameter(index: 0),
      'pos' << match.Parameter(index: 1),
      match.CheckStackOverflow(),
      'cid1' << match.LoadClassId('value'),
      match.Branch(match.TestRange('cid1'), ifTrue: 'B10', ifFalse: 'B11'),
    ]),
    'B10' <<
        match.block('Target', [
          match.MoveArgument('value'),
          'value_length1' << match.DispatchTableCall('cid1'),
          match.Goto('B12'),
        ]),
    'B11' <<
        match.block('Target', [
          match.MoveArgument('value'),
          'value_length2' << match.InstanceCall('value'),
          match.Goto('B12'),
        ]),
    'B12' <<
        match.block('Join', [
          'value_length' << match.Phi('value_length1', 'value_length2'),
          'value_length_unboxed' << match.UnboxInt64('value_length'),
          match.Branch(
              match.EqualityCompare('pos', 'value_length_unboxed', kind: '=='),
              ifTrue: 'B3',
              ifFalse: 'B4'),
        ]),
    'B3' <<
        match.block('Target', [
          match.Goto('B9'),
        ]),
    'B4' <<
        match.block('Target', [
          match.Goto('B5'),
        ]),
    'B5' << match.tryBlock(tryBody: 'B6', catches: 'B8'),
    'B6' <<
        match.block('Join', [
          'pos_boxed' << match.BoxInt64('pos'),
          'cid2' << match.LoadClassId('value'),
          match.Branch(match.TestRange('cid2'), ifTrue: 'B13', ifFalse: 'B14'),
        ]),
    'B13' <<
        match.block('Target', [
          match.MoveArgument('value'),
          match.MoveArgument('pos_boxed'),
          'value_substring1' << match.DispatchTableCall('cid2'),
          match.Goto('B15'),
        ]),
    'B14' <<
        match.block('Target', [
          match.MoveArgument('value'),
          match.MoveArgument('pos_boxed'),
          'value_substring2' << match.InstanceCall('value', 'pos_boxed'),
          match.Goto('B15'),
        ]),
    'B15' <<
        match.block('Join', [
          'value_substring' <<
              match.Phi('value_substring1', 'value_substring2'),
          match.MoveArgument('value_substring'),
          match.StaticCall('value_substring'),
          match.Goto('B7'),
        ]),
    'B8' <<
        match.block('CatchBlock', [
          match.Goto('B7'),
        ]),
    'B7' <<
        match.block('Join', [
          match.Goto('B9'),
        ]),
    'B9' <<
        match.block('Join', [
          match.DartReturn(match.any),
        ]),
  ]);
}
