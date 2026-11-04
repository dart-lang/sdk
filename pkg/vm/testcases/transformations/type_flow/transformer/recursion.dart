// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that TFA infers precise return types across recursive invocations
// via fixed-point iteration instead of falling back to static return types.

void main() {
  testDirectRecursion();
  testMutualRecursion();
  testPolymorphicRecursion();
  testMultiStepRecursion();
}

// -----------------------------------------------------------------------------
// 1. Direct recursion: return type inferred as `_Array<int>` instead of `List`.
// -----------------------------------------------------------------------------

void testDirectRecursion() {
  print(buildListDirect(3));
}

List<int> buildListDirect(int n) {
  if (n <= 0) return const <int>[];
  if (n.isOdd) return buildListDirect(n - 1);
  return List<int>.filled(n, 0, growable: false);
}

// -----------------------------------------------------------------------------
// 2. Mutual recursion: return types inferred as `_Array<int>` instead of `List`.
// -----------------------------------------------------------------------------

void testMutualRecursion() {
  print(buildListEven(3));
}

List<int> buildListEven(int n) {
  if (n <= 0) return const <int>[];
  return buildListOdd(n - 1);
}

List<int> buildListOdd(int n) {
  if (n.isOdd) return buildListEven(n - 1);
  return List<int>.filled(n, 0, growable: false);
}

// -----------------------------------------------------------------------------
// 3. Polymorphic recursion (e.g. recursive AST/tree traversal):
//    `Node.eval` inferred to return `IntValue` instead of `Value`.
// -----------------------------------------------------------------------------

void testPolymorphicRecursion() {
  // Allocate StringValue so `Value` has multiple allocated subtypes.
  print(StringValue());

  final Node tree = NegateNode(NegateNode(LiteralNode()));
  print(tree.eval());
}

abstract class Value {}

class IntValue implements Value {}

class StringValue implements Value {}

abstract class Node {
  Value eval();
}

class LiteralNode implements Node {
  @override
  Value eval() => IntValue();
}

class NegateNode implements Node {
  final Node operand;
  NegateNode(this.operand);

  @override
  Value eval() => operand.eval();
}

// -----------------------------------------------------------------------------
// 4. Multi-step fixed-point iteration:
//    Each iteration discovers a new subtype (`Step0` -> `Step1` -> `Step2`),
//    converging to `ValidStep` without widening to `StepValue`.
// -----------------------------------------------------------------------------

void testMultiStepRecursion() {
  // Allocate UnusedStep so `StepValue` is wider than `ValidStep`.
  print(UnusedStep());

  final result = multiStep(3);
  if (result is Step2) {
    result.reached();
  }
  if (result is UnusedStep) {
    result.unreachable();
  }
}

StepValue multiStep(int n) {
  if (n <= 0) return Step0();
  final prev = multiStep(n - 1);
  if (prev is Step0) return Step1();
  if (prev is Step1) return Step2();
  return prev;
}

abstract class StepValue {}

abstract class ValidStep extends StepValue {}

class Step0 extends ValidStep {}

class Step1 extends ValidStep {}

class Step2 extends ValidStep {
  void reached() => print('Step2');
}

class UnusedStep extends StepValue {
  void unreachable() => print('UnusedStep');
}
