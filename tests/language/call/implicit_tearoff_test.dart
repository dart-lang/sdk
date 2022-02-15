// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test exercises all the grammar constructs for which implicit tear-off of
// `call` methods should occur.

// NOTICE: This test checks the currently implemented behavior, even though the
// implemented behavior does not match the language specification.  Until an
// official decision has been made about whether to change the implementation to
// match the specification, or vice versa, this regression test is intended to
// protect against inadvertent implementation changes.

import '../static_type_helper.dart';

class B {}

class C extends B {
  void call() {}
  void m() {}
  void testThisExpression() {
    context<void Function()>(this);
  }
}

class D {
  C operator +(other) => C();
  C operator -() => C();
  C instanceMethod() => C();
  static C staticMethod() => C();
  C get instanceGetter => C();
}

C topLevelMethod() => C();

// These are top level getters rather than local variables to avoid triggering
// flow analysis.
bool get bTrue => true;
bool get bFalse => false;

void testAsExpression() {
  dynamic d = C();
  context<void Function()>(d as C);
}

void testAssignmentExpression() {
  B b = B(); // ignore: unused_local_variable
  context<void Function()>(b = C());
}

Future<void> testAwaitExpression() async {
  Future<C> fc = Future.value(C());
  context<void Function()>(await fc);
}

void testBinaryExpression() {
  D d = D();
  context<void Function()>(d + d);
}

void testCascadeExpression() {
  // Note: we don't apply implicit `.call` tear-offs to the *target* of a
  // cascade, but we do apply them to the cascade expression as a whole, so
  // `c..m()` is equivalent to `(c..m()).call`.
  C c = C();
  context<void Function()>(c..m());
}

void testConditionalExpression() {
  // Note: we know from `implicit_tearoff_exceptions_test.dart` that the two
  // branches of the conditional expression are *not* subject to implicit
  // `.call` tearoff, so the `.call` tearoff in this case is applied to the
  // whole conditional expression.  In other words, `b ? c : c` desugars to
  // `(b ? c : c).call` rather than `(b ? c.call : c.call)`.
  C c = C();
  context<void Function()>(bFalse ? c : c);
  context<void Function()>(bTrue ? c : c);
}

void testFunctionExpressionInvocation() {
  C c = C();
  context<void Function()>((() => c)());
}

void testFunctionInvocationLocal() {
  C localFunction() => C();
  context<void Function()>(localFunction());
}

void testFunctionInvocationStatic() {
  context<void Function()>(D.staticMethod());
}

void testFunctionInvocationTopLevel() {
  context<void Function()>(topLevelMethod());
}

void testIfNullExpression() {
  C? c1 = bTrue ? C() : null;
  C c2 = C();
  context<void Function()>(c1 ?? c2);
  c1 = null;
  context<void Function()>(c1 ?? c2);
}

void testIndexExpression() {
  List<C> l = [C()];
  context<void Function()>(l[0]);
}

void testInstanceCreationExpressionExplicit() {
  context<void Function()>(new C());
}

void testInstanceCreationExpressionImplicit() {
  context<void Function()>(C());
}

void testInstanceGetGeneral() {
  D Function() dFunction = () => D();
  context<void Function()>(dFunction().instanceGetter);
}

void testInstanceGetViaPrefixedIdentifier() {
  D d = D();
  context<void Function()>(d.instanceGetter);
}

void testMethodInvocation() {
  context<void Function()>(D().instanceMethod());
}

void testNullCheckExpression() {
  C? c = bTrue ? C() : null;
  context<void Function()>(c!);
}

void testParenthesizedExpression() {
  C c = C();
  context<void Function()>((c));
}

void testUnaryMinusExpression() {
  D d = D();
  context<void Function()>(-d);
}

extension on C {
  void testThisExpressionExtension() {
    context<void Function()>(this);
  }
}

main() async {
  testAsExpression();
  testAssignmentExpression();
  await testAwaitExpression();
  testBinaryExpression();
  testCascadeExpression();
  testConditionalExpression();
  testFunctionExpressionInvocation();
  testFunctionInvocationLocal();
  testFunctionInvocationStatic();
  testFunctionInvocationTopLevel();
  testIfNullExpression();
  testIndexExpression();
  testInstanceCreationExpressionExplicit();
  testInstanceCreationExpressionImplicit();
  testInstanceGetGeneral();
  testInstanceGetViaPrefixedIdentifier();
  testMethodInvocation();
  testNullCheckExpression();
  testParenthesizedExpression();
  testUnaryMinusExpression();
  C().testThisExpression();
  C().testThisExpressionExtension();
}
