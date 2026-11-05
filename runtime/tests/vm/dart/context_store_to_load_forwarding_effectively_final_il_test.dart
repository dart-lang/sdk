// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies store-to-load forwarding for captured `this`, parameters, and local
// variables:
// - Forwarding applies when variables are effectively final or non-late final,
//   as their context slots are marked immutable.
// - Forwarding does not apply when captured variables are reassigned.

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';

void main() {
  Expect.equals(0x200000000 + 52, helper(B(), A()));
  Expect.equals(0x200000000 + 52, testStoreToLoadForwarding());

  Expect.equals(0x200000000 + 52, B().helperThis(A()));
  Expect.equals(0x200000000 + 52, testThisStoreToLoadForwarding());

  Expect.equals(0x200000000 + 52, helperNotEffectivelyFinal(B(), A()));
  Expect.equals(0x200000000 + 52, testNoStoreToLoadForwarding());

  Expect.equals(0x200000000 + 84, testSplitFinalStoreToLoadForwarding(true));
  Expect.equals(0x200000000 + 20, testSplitFinalStoreToLoadForwarding(false));
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testStoreToLoadForwarding() {
  return helper(A(), B());
}

void matchIL$testStoreToLoadForwarding(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.CheckStackOverflow(),
      'a' << match.AllocateObject(),
      'ctx' << match.AllocateContext(),
      match.StoreField('ctx', 'a'),
      'y' << match.AllocateObject(),
      match.StoreField('ctx', 'y'),
      'closure' << match.AllocateClosure(match.any, 'ctx'),
      match.MoveArgument('closure'),
      match.StaticCall(), // escape(closure)
      // `a` is store-to-load forwarded from `ctx` (devirtualizing `a.foo()`).
      match.MoveArgument('a'),
      'res_a' << match.StaticCall(),
      // `y` is store-to-load forwarded from `ctx` (devirtualizing `y.foo()`).
      match.MoveArgument('y'),
      'res_y' << match.StaticCall(),
      'res' << match.BinaryInt64Op('res_a', 'res_y'),
      match.DartReturn('res'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testThisStoreToLoadForwarding() {
  return A().helperThis(B());
}

void matchIL$testThisStoreToLoadForwarding(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.CheckStackOverflow(),
      'a' << match.AllocateObject(),
      'ctx' << match.AllocateContext(),
      match.StoreField('ctx', 'a'),
      'y' << match.AllocateObject(),
      match.StoreField('ctx', 'y'),
      'closure' << match.AllocateClosure(match.any, 'ctx'),
      match.MoveArgument('closure'),
      match.StaticCall(), // escape(closure)
      // `this` (`a`) is store-to-load forwarded from `ctx` (devirtualizing `this.foo()`).
      match.MoveArgument('a'),
      'res_a' << match.StaticCall(),
      // `y` is store-to-load forwarded from `ctx` (devirtualizing `y.foo()`).
      match.MoveArgument('y'),
      'res_y' << match.StaticCall(),
      'res' << match.BinaryInt64Op('res_a', 'res_y'),
      match.DartReturn('res'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testNoStoreToLoadForwarding() {
  return helperNotEffectivelyFinal(A(), B());
}

void matchIL$testNoStoreToLoadForwarding(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      match.CheckStackOverflow(),
      'a' << match.AllocateObject(),
      'ctx' << match.AllocateContext(),
      match.StoreField('ctx', 'a'),
      'y' << match.AllocateObject(),
      match.StoreField('ctx', 'y'),
      'closure' << match.AllocateClosure(match.any, 'ctx'),
      match.MoveArgument('closure'),
      match.StaticCall(), // escape(closure)
      // `a` is not effectively final, so it must be reloaded from `ctx`.
      'loaded_a' << match.LoadField('ctx'),
      match.MoveArgument('loaded_a'),
      'res_a' << match.DispatchTableCall(),
      // `y` is not effectively final, so it must be reloaded from `ctx`.
      'loaded_y' << match.LoadField('ctx'),
      match.MoveArgument('loaded_y'),
      'res_y' << match.DispatchTableCall(),
      'res' << match.BinaryInt64Op('res_a', 'res_y'),
      match.DartReturn('res'),
    ]),
  ]);
}

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
int testSplitFinalStoreToLoadForwarding(bool b) {
  final I a;
  final int branchRes;
  if (b) {
    a = A();
    final f = () => a.foo();
    escape(f);
    branchRes = callClosure(f);
  } else {
    a = B();
    final f = () => a.foo();
    escape(f);
    branchRes = callClosure(f);
  }
  final f = () => a.foo();
  escape(f);
  return branchRes + callClosure(f);
}

void matchIL$testSplitFinalStoreToLoadForwarding(FlowGraph graph) {
  graph.match([
    match.block('Graph', [
      'c_true' << match.Constant(value: true),
      'c_cid_a' << match.UnboxedConstant(),
      'c_cid_b' << match.UnboxedConstant(),
    ]),
    match.block('Function', [
      'b' << match.Parameter(index: 0),
      match.CheckStackOverflow(),
      'ctx' << match.AllocateContext(),
      match.Branch(
        match.StrictCompare('b', 'c_true'),
        ifTrue: 'B_then',
        ifFalse: 'B_else',
      ),
    ]),
    'B_then' <<
        match.block('Target', [
          'a1' << match.AllocateObject(),
          match.StoreField('ctx', 'a1'),
          'closure1' << match.AllocateClosure(match.any, 'ctx'),
          match.MoveArgument('closure1'),
          match.StaticCall(), // escape(closure1)
          // `a1` is store-to-load forwarded from `ctx` by CSE in the `then`
          // branch, folding `LoadClassId(a1)` into a constant.
          match.MoveArgument('a1'),
          'res1' << match.DispatchTableCall('c_cid_a'),
          match.Goto('B_join'),
        ]),
    'B_else' <<
        match.block('Target', [
          'a2' << match.AllocateObject(),
          match.StoreField('ctx', 'a2'),
          'closure2' << match.AllocateClosure(match.any, 'ctx'),
          match.MoveArgument('closure2'),
          match.StaticCall(), // escape(closure2)
          // `a2` is store-to-load forwarded from `ctx` by CSE in the `else`
          // branch, folding `LoadClassId(a2)` into a constant.
          match.MoveArgument('a2'),
          'res2' << match.DispatchTableCall('c_cid_b'),
          match.Goto('B_join'),
        ]),
    'B_join' <<
        match.block('Join', [
          'branch_res' << match.Phi('res1', 'res2'),
          'phi_a' << match.Phi('a1', 'a2'),
          'closure3' << match.AllocateClosure(match.any, 'ctx'),
          match.MoveArgument('closure3'),
          match.StaticCall(), // escape(closure3)
          // At the join point, CSE merges the forwarded values into `phi_a`.
          'cid' << match.LoadClassId('phi_a'),
          match.MoveArgument('phi_a'),
          'after_res' << match.DispatchTableCall('cid'),
          'total' << match.BinaryInt64Op('branch_res', 'after_res'),
          match.DartReturn('total'),
        ]),
  ]);
}

// We expect the (effectively final) captured `a` parameter and local `y`
// variable to be store-to-load forwarded.
@pragma('vm:prefer-inline')
int helper(I a, I b) {
  I y = b;
  final f = () => a.foo() + y.foo();
  escape(f);
  return callClosure(f);
}

// We expect the captured `a` parameter and local `y` variable to *not* be
// store-to-load forwarded.
@pragma('vm:prefer-inline')
int helperNotEffectivelyFinal(I a, I b) {
  a = a;
  I y = b;
  y = y;
  final f = () => a.foo() + y.foo();
  escape(f);
  return callClosure(f);
}

@pragma('vm:prefer-inline')
int callClosure(int Function() f) => f();

Object? escapedClosure;

@pragma('vm:never-inline')
void escape(Object? o) {
  escapedClosure = o;
}

abstract class I {
  int foo();

  @pragma('vm:prefer-inline')
  int helperThis(I b) {
    I y = b;
    final f = () => this.foo() + y.foo();
    escape(f);
    return callClosure(f);
  }
}

class A extends I {
  @pragma('vm:never-inline')
  int foo() => 0x100000000 + 42;
}

class B extends I {
  @pragma('vm:never-inline')
  int foo() => 0x100000000 + 10;
}
