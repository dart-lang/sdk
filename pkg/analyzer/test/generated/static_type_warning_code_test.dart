// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StaticTypeWarningCodeTest);
    defineReflectiveTests(StrongModeStaticTypeWarningCodeTest);
  });
}

@reflectiveTest
class StaticTypeWarningCodeTest extends DriverResolutionTest {
  test_assert_message_suppresses_type_promotion() async {
    // If a variable is assigned to inside the expression for an assert
    // message, type promotion should be suppressed, just as it would be if the
    // assignment occurred outside an assert statement.  (Note that it is a
    // dubious practice for the computation of an assert message to have side
    // effects, since it is only evaluated if the assert fails).
    await assertErrorsInCode('''
class C {
  void foo() {}
}

f(Object x) {
  if (x is C) {
    x.foo();
    assert(true, () { x = new C(); return 'msg'; }());
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 65, 3),
    ]);
  }

  test_await_flattened() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<Future<int>> ffi() => null;
f() async {
  Future<int> b = await ffi(); 
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 82, 1),
    ]);
  }

  test_await_simple() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<int> fi() => null;
f() async {
  String a = await fi(); // Warning: int not assignable to String
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 68, 1),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 72, 10),
    ]);
  }

  test_awaitForIn_declaredVariableRightType() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  await for (int i in stream) {}
}
''');
  }

  test_awaitForIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
import 'dart:async';
f() async {
  Stream<String> stream;
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 75, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 80, 6),
    ]);
  }

  test_awaitForIn_downcast() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<num> stream;
  await for (int i in stream) {}
}
''');
  }

  test_awaitForIn_dynamicStream() async {
    await assertNoErrorsInCode('''
f() async {
  dynamic stream;
  await for (int i in stream) {}
}
''');
  }

  test_awaitForIn_dynamicVariable() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  await for (var i in stream) {}
}
''');
  }

  test_awaitForIn_existingVariableRightType() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  int i;
  await for (i in stream) {}
}
''');
  }

  test_awaitForIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
import 'dart:async';
f() async {
  Stream<String> stream;
  int i;
  await for (i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 64, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 85, 6),
    ]);
  }

  test_awaitForIn_notStream() async {
    await assertErrorsInCode('''
f() async {
  await for (var i in true) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 34, 4),
    ]);
  }

  test_awaitForIn_streamOfDynamic() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream stream;
  await for (int i in stream) {}
}
''');
  }

  test_awaitForIn_upcast() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  await for (num i in stream) {}
}
''');
  }

  test_bug21912() async {
    await assertErrorsInCode('''
class A {}
class B extends A {}

typedef T Function2<S, T>(S z);
typedef B AToB(A x);
typedef A BToA(B x);

void main() {
  {
    Function2<Function2<A, B>, Function2<B, A>> t1;
    Function2<AToB, BToA> t2;

    Function2<Function2<int, double>, Function2<int, double>> left;

    left = t1;
    left = t2;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 271, 4),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 289, 2),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 304, 2),
    ]);
  }

  test_expectedOneListTypeArgument() async {
    await assertErrorsInCode(r'''
main() {
  <int, int> [];
}
''', [
      error(StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS, 11, 10),
    ]);
  }

  test_expectedOneSetTypeArgument() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{2, 3};
}
''', [
      error(StaticTypeWarningCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_expectedTwoMapTypeArguments_three() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int> {};
}
''', [
      error(StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_forIn_declaredVariableRightType() async {
    await assertNoErrorsInCode('''
f() {
  for (int i in <int>[]) {}
}
''');
  }

  test_forIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 22, 10),
    ]);
  }

  test_forIn_downcast() async {
    await assertNoErrorsInCode('''
f() {
  for (int i in <num>[]) {}
}
''');
  }

  test_forIn_dynamic() async {
    await assertNoErrorsInCode('''
f() {
  dynamic d; // Could be [].
  for (var i in d) {}
}
''');
  }

  test_forIn_dynamicIterable() async {
    await assertNoErrorsInCode('''
f() {
  dynamic iterable;
  for (int i in iterable) {}
}
''');
  }

  test_forIn_dynamicVariable() async {
    await assertNoErrorsInCode('''
f() {
  for (var i in <int>[]) {}
}
''');
  }

  test_forIn_existingVariableRightType() async {
    await assertNoErrorsInCode('''
f() {
  int i;
  for (i in <int>[]) {}
}
''');
  }

  test_forIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 27, 10),
    ]);
  }

  test_forIn_iterableOfDynamic() async {
    await assertNoErrorsInCode('''
f() {
  for (int i in []) {}
}
''');
  }

  test_forIn_notIterable() async {
    await assertErrorsInCode('''
f() {
  for (var i in true) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 22, 4),
    ]);
  }

  test_forIn_object() async {
    await assertNoErrorsInCode('''
f() {
  Object o; // Could be [].
  for (var i in o) {}
}
''');
  }

  test_forIn_typeBoundBad() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 86, 8),
    ]);
  }

  test_forIn_typeBoundGood() async {
    await assertNoErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (var i in iterable) {}
  }
}
''');
  }

  test_forIn_upcast() async {
    await assertNoErrorsInCode('''
f() {
  for (num i in <int>[]) {}
}
''');
  }

  test_illegalAsyncGeneratorReturnType_function_nonStream() async {
    await assertErrorsInCode('''
int f() async* {}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 3),
    ]);
  }

  test_illegalAsyncGeneratorReturnType_function_subtypeOfStream() async {
    await assertErrorsInCode('''
import 'dart:async';
abstract class SubStream<T> implements Stream<T> {}
SubStream<int> f() async* {}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 73, 14),
    ]);
  }

  test_illegalAsyncGeneratorReturnType_method_nonStream() async {
    await assertErrorsInCode('''
class C {
  int f() async* {}
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 12, 3),
    ]);
  }

  test_illegalAsyncGeneratorReturnType_method_subtypeOfStream() async {
    await assertErrorsInCode('''
import 'dart:async';
abstract class SubStream<T> implements Stream<T> {}
class C {
  SubStream<int> f() async* {}
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 85, 14),
    ]);
  }

  test_illegalAsyncReturnType_function_nonFuture() async {
    await assertErrorsInCode('''
int f() async {}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
      error(HintCode.MISSING_RETURN, 0, 3),
    ]);
  }

  test_illegalAsyncReturnType_function_subtypeOfFuture() async {
    await assertErrorsInCode('''
import 'dart:async';
abstract class SubFuture<T> implements Future<T> {}
SubFuture<int> f() async {
  return 0;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 73, 14),
    ]);
  }

  test_illegalAsyncReturnType_method_nonFuture() async {
    await assertErrorsInCode('''
class C {
  int m() async {}
}
''', [
      error(HintCode.MISSING_RETURN, 12, 3),
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 12, 3),
    ]);
  }

  test_illegalAsyncReturnType_method_subtypeOfFuture() async {
    await assertErrorsInCode('''
import 'dart:async';
abstract class SubFuture<T> implements Future<T> {}
class C {
  SubFuture<int> m() async {
    return 0;
  }
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 85, 14),
    ]);
  }

  test_illegalSyncGeneratorReturnType_function_nonIterator() async {
    await assertErrorsInCode('''
int f() sync* {}
''', [
      error(StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 0, 3),
    ]);
  }

  test_illegalSyncGeneratorReturnType_function_subclassOfIterator() async {
    await assertErrorsInCode('''
abstract class SubIterator<T> implements Iterator<T> {}
SubIterator<int> f() sync* {}
''', [
      error(StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 56, 16),
    ]);
  }

  test_illegalSyncGeneratorReturnType_method_nonIterator() async {
    await assertErrorsInCode('''
class C {
  int f() sync* {}
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 12, 3),
    ]);
  }

  test_illegalSyncGeneratorReturnType_method_subclassOfIterator() async {
    await assertErrorsInCode('''
abstract class SubIterator<T> implements Iterator<T> {}
class C {
  SubIterator<int> f() sync* {}
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 68, 16),
    ]);
  }

  test_instanceAccessToStaticMember_method_reference() async {
    await assertErrorsInCode(r'''
class A {
  static m() {}
}
main(A a) {
  a.m;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 44, 1),
    ]);
  }

  test_instanceAccessToStaticMember_propertyAccess_field() async {
    await assertErrorsInCode(r'''
class A {
  static var f;
}
main(A a) {
  a.f;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 44, 1),
    ]);
  }

  test_instanceAccessToStaticMember_propertyAccess_getter() async {
    await assertErrorsInCode(r'''
class A {
  static get f => 42;
}
main(A a) {
  a.f;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 50, 1),
    ]);
  }

  test_instanceAccessToStaticMember_propertyAccess_setter() async {
    await assertErrorsInCode(r'''
class A {
  static set f(x) {}
}
main(A a) {
  a.f = 42;
}
''', [
      error(StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER, 49, 1),
    ]);
  }

  test_invalidAssignment_compoundAssignment() async {
    await assertErrorsInCode(r'''
class byte {
  int _value;
  byte(this._value);
  int operator +(int val) { return 0; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}
''', [
      error(HintCode.UNUSED_FIELD, 19, 6),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 112, 1),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 137, 1),
    ]);
  }

  test_invalidAssignment_defaultValue_named() async {
    await assertErrorsInCode(r'''
f({String x: 0}) {
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 13, 1),
    ]);
  }

  test_invalidAssignment_defaultValue_optional() async {
    await assertErrorsInCode(r'''
f([String x = 0]) {
}''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 14, 1),
    ]);
  }

  test_invalidAssignment_dynamic() async {
    await assertErrorsInCode(r'''
main() {
  dynamic = 1;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 21, 1),
    ]);
  }

  test_invalidAssignment_functionExpressionInvocation() async {
    await assertErrorsInCode('''
main() {
  String x = (() => 5)();
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 22, 11),
    ]);
  }

  test_invalidAssignment_ifNullAssignment() async {
    await assertErrorsInCode('''
void f(int i) {
  double d;
  d ??= i;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 36, 1),
    ]);
  }

  test_invalidAssignment_instanceVariable() async {
    await assertErrorsInCode(r'''
class A {
  int x;
}
f() {
  A a;
  a.x = '0';
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 42, 3),
    ]);
  }

  test_invalidAssignment_localVariable() async {
    await assertErrorsInCode(r'''
f() {
  int x;
  x = '0';
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 21, 3),
    ]);
  }

  test_invalidAssignment_postfixExpression_localVariable() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

f(A a) {
  a++;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 65, 3),
    ]);
  }

  test_invalidAssignment_postfixExpression_property() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

class C {
  A a;
}

f(C c) {
  c.a++;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 85, 5),
    ]);
  }

  test_invalidAssignment_prefixExpression_localVariable() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

f(A a) {
  ++a;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 65, 3),
    ]);
  }

  test_invalidAssignment_prefixExpression_property() async {
    await assertErrorsInCode(r'''
class A {
  B operator+(_) => new B();
}

class B {}

class C {
  A a;
}

f(C c) {
  ++c.a;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 85, 5),
    ]);
  }

  test_invalidAssignment_regressionInIssue18468Fix() async {
    // https://code.google.com/p/dart/issues/detail?id=18628
    await assertErrorsInCode(r'''
class C<T> {
  T t = int;
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 21, 3),
    ]);
  }

  test_invalidAssignment_staticVariable() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
}
f() {
  A.x = '0';
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 42, 3),
    ]);
  }

  test_invalidAssignment_topLevelVariableDeclaration() async {
    await assertErrorsInCode('''
int x = 'string';
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 8, 8),
    ]);
  }

  test_invalidAssignment_typeParameter() async {
    // 14221
    await assertErrorsInCode(r'''
class B<T> {
  T value;
  void test(num n) {
    value = n;
  }
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 57, 1),
    ]);
  }

  test_invalidAssignment_variableDeclaration() async {
    await assertErrorsInCode(r'''
class A {
  int x = 'string';
}
''', [
      error(StaticTypeWarningCode.INVALID_ASSIGNMENT, 20, 8),
    ]);
  }

  test_invocationOfNonFunctionExpression_literal() async {
    await assertErrorsInCode(r'''
f() {
  3(5);
}
''', [
      error(StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 8, 1),
    ]);
  }

  test_nonBoolCondition_conditional() async {
    await assertErrorsInCode('''
f() { return 3 ? 2 : 1; }
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 13, 1),
    ]);
  }

  test_nonBoolCondition_do() async {
    await assertErrorsInCode(r'''
f() {
  do {} while (3);
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 21, 1),
    ]);
  }

  test_nonBoolCondition_for() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (;3;) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 14, 1),
    ]);
  }

  test_nonBoolCondition_if() async {
    await assertErrorsInCode(r'''
f() {
  if (3) return 2; else return 1;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 12, 1),
    ]);
  }

  test_nonBoolCondition_while() async {
    await assertErrorsInCode(r'''
f() {
  while (3) {}
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 15, 1),
    ]);
  }

  test_nonBoolExpression_functionType_bool() async {
    await assertErrorsInCode(r'''
bool makeAssertion() => true;
f() {
  assert(makeAssertion);
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_EXPRESSION, 45, 13),
    ]);
  }

  test_nonBoolExpression_functionType_int() async {
    await assertErrorsInCode(r'''
int makeAssertion() => 1;
f() {
  assert(makeAssertion);
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_EXPRESSION, 41, 13),
    ]);
  }

  test_nonBoolExpression_interfaceType() async {
    await assertErrorsInCode(r'''
f() {
  assert(0);
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_EXPRESSION, 15, 1),
    ]);
  }

  test_nonBoolNegationExpression() async {
    await assertErrorsInCode(r'''
f() {
  !42;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION, 9, 2),
    ]);
  }

  test_nonBoolOperand_and_left() async {
    await assertErrorsInCode(r'''
bool f(int left, bool right) {
  return left && right;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 40, 4),
    ]);
  }

  test_nonBoolOperand_and_right() async {
    await assertErrorsInCode(r'''
bool f(bool left, String right) {
  return left && right;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 51, 5),
    ]);
  }

  test_nonBoolOperand_or_left() async {
    await assertErrorsInCode(r'''
bool f(List<int> left, bool right) {
  return left || right;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 46, 4),
    ]);
  }

  test_nonBoolOperand_or_right() async {
    await assertErrorsInCode(r'''
bool f(bool left, double right) {
  return left || right;
}
''', [
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 51, 5),
    ]);
  }

  test_nonTypeAsTypeArgument_notAType() async {
    await assertErrorsInCode(r'''
int A;
class B<E> {}
f(B<A> b) {}
''', [
      error(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, 25, 1),
    ]);
  }

  test_nonTypeAsTypeArgument_undefinedIdentifier() async {
    await assertErrorsInCode(r'''
class B<E> {}
f(B<A> b) {}
''', [
      error(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, 18, 1),
    ]);
  }

  test_returnOfInvalidType_async_future_future_int_mismatches_future_int() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<int> f() async {
  return g();
}
Future<Future<int>> g() => null;
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 54, 3),
    ]);
  }

  test_returnOfInvalidType_async_future_int_mismatches_future_string() async {
    await assertErrorsInCode('''
import 'dart:async';
Future<String> f() async {
  return 5;
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 57, 1),
    ]);
  }

  test_returnOfInvalidType_async_future_int_mismatches_int() async {
    await assertErrorsInCode('''
int f() async {
  return 5;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE, 0, 3),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 25, 1),
    ]);
  }

  test_returnOfInvalidType_expressionFunctionBody_function() async {
    await assertErrorsInCode('''
int f() => '0';
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 11, 3),
    ]);
  }

  test_returnOfInvalidType_expressionFunctionBody_getter() async {
    await assertErrorsInCode('''
int get g => '0';
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 13, 3),
    ]);
  }

  test_returnOfInvalidType_expressionFunctionBody_localFunction() async {
    await assertErrorsInCode(r'''
class A {
  String m() {
    int f() => '0';
    return '0';
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 33, 1),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 40, 3),
    ]);
  }

  test_returnOfInvalidType_expressionFunctionBody_method() async {
    await assertErrorsInCode(r'''
class A {
  int f() => '0';
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 23, 3),
    ]);
  }

  test_returnOfInvalidType_function() async {
    await assertErrorsInCode('''
int f() { return '0'; }
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 17, 3),
    ]);
  }

  test_returnOfInvalidType_getter() async {
    await assertErrorsInCode('''
int get g { return '0'; }
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 19, 3),
    ]);
  }

  test_returnOfInvalidType_localFunction() async {
    await assertErrorsInCode(r'''
class A {
  String m() {
    int f() { return '0'; }
    return '0';
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 33, 1),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 46, 3),
    ]);
  }

  test_returnOfInvalidType_method() async {
    await assertErrorsInCode(r'''
class A {
  int f() { return '0'; }
}
''', [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 29, 3),
    ]);
  }

  test_returnOfInvalidType_not_issued_for_expressionFunctionBody_void() async {
    await assertNoErrorsInCode('''
void f() => 42;
''');
  }

  test_returnOfInvalidType_not_issued_for_valid_generic_return() async {
    await assertNoErrorsInCode(r'''
abstract class F<T, U>  {
  U get value;
}

abstract class G<T> {
  T test(F<int, T> arg) => arg.value;
}

abstract class H<S> {
  S test(F<int, S> arg) => arg.value;
}

void main() { }
''');
  }

  test_returnOfInvalidType_void() async {
    await assertErrorsInCode("void f() { return 42; }", [
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 18, 2),
    ]);
  }

  test_typeParameterSupertypeOfItsBound_1of1() async {
    await assertErrorsInCode(r'''
class A<T extends T> {
}
''', [
      error(StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 8, 11),
    ]);
  }

  test_typeParameterSupertypeOfItsBound_2of3() async {
    await assertErrorsInCode(r'''
class A<T1 extends T3, T2, T3 extends T1> {
}
''', [
      error(StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 8, 13),
      error(
          StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND, 27, 13),
    ]);
  }

  test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_mutated() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
  p = 0;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 71, 6),
    ]);
  }

  test_typePromotion_booleanAnd_useInRight_mutatedInLeft() async {
    await assertErrorsInCode(r'''
main(Object p) {
  ((p is String) && ((p = 42) == 42)) && p.length != 0;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 60, 6),
    ]);
  }

  test_typePromotion_booleanAnd_useInRight_mutatedInRight() async {
    await assertErrorsInCode(r'''
main(Object p) {
  (p is String) && (((p = 42) == 42) && p.length != 0);
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 59, 6),
    ]);
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_after() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
  p = 42;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 68, 6),
    ]);
  }

  test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_before() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  p = 42;
  p is String ? callMe(() { p.length; }) : 0;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 78, 6),
    ]);
  }

  test_typePromotion_conditional_useInThen_hasAssignment() async {
    await assertErrorsInCode(r'''
main(Object p) {
  p is String ? (p.length + (p = 42)) : 0;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 36, 6),
    ]);
  }

  test_typePromotion_if_accessedInClosure_hasAssignment() async {
    await assertErrorsInCode(r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
  p = 0;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 83, 6),
    ]);
  }

  test_typePromotion_if_and_right_hasAssignment() async {
    await assertErrorsInCode(r'''
main(Object p) {
  if (p is String && (p = null) == null) {
    p.length;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 66, 6),
    ]);
  }

  test_typePromotion_if_extends_notMoreSpecific_dynamic() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 100, 1),
    ]);
  }

  test_typePromotion_if_extends_notMoreSpecific_notMoreSpecificTypeArg() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<int>) {
    p.b;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 105, 1),
    ]);
  }

  test_typePromotion_if_hasAssignment_after() async {
    await assertErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
    p = 0;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 44, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_before() async {
    await assertErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p = 0;
    p.length;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 55, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_anonymous_after() async {
    await assertErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  () {p = 0;};
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 44, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_anonymous_before() async {
    await assertErrorsInCode(r'''
main(Object p) {
  () {p = 0;};
  if (p is String) {
    p.length;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 59, 6),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_function_after() async {
    await assertErrorsInCode(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  f() {p = 0;};
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 44, 6),
      error(HintCode.UNUSED_ELEMENT, 58, 1),
    ]);
  }

  test_typePromotion_if_hasAssignment_inClosure_function_before() async {
    await assertErrorsInCode(r'''
main(Object p) {
  f() {p = 0;};
  if (p is String) {
    p.length;
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 19, 1),
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 60, 6),
    ]);
  }

  test_typePromotion_if_implements_notMoreSpecific_dynamic() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 103, 1),
    ]);
  }

  test_typePromotion_if_with_notMoreSpecific_dynamic() async {
    await assertErrorsInCode(r'''
class V {}
class A<T> {}
class B<S> extends Object with A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 112, 1),
    ]);
  }

  test_undefinedEnumConstant() async {
    // We should be reporting UNDEFINED_ENUM_CONSTANT here.
    await assertErrorsInCode(r'''
enum E { ONE }
E e() {
  return E.TWO;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 34, 3),
    ]);
  }

  test_undefinedGetter() async {
    await assertErrorsInCode(r'''
class T {}
f(T e) { return e.m; }
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 29, 1),
    ]);
  }

  test_undefinedGetter_generic_function_call() async {
    // Referencing `.call` on a `Function` type works similarly to referencing
    // it on `dynamic`--the reference is accepted at compile time, and all type
    // checking is deferred until runtime.
    await assertErrorsInCode('''
f(Function f) {
  return f.call;
}
''', []);
  }

  test_undefinedGetter_object_call() async {
    await assertErrorsInCode('''
f(Object o) {
  return o.call;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 25, 4),
    ]);
  }

  test_undefinedGetter_proxy_annotation_fakeProxy() async {
    await assertErrorsInCode(r'''
library L;
class Fake {
  const Fake();
}
const proxy = const Fake();
@proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 127, 3),
    ]);
  }

  test_undefinedGetter_static() async {
    await assertErrorsInCode(r'''
class A {}
var a = A.B;''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 21, 1),
    ]);
  }

  test_undefinedGetter_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class T {
  static int get foo => 42;
}
main() {
  T..foo;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 54, 3),
    ]);
  }

  test_undefinedGetter_typeLiteral_conditionalAccess() async {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance getters of Type.
    await assertErrorsInCode('''
class A {}
f() => A?.hashCode;
''', [
      error(StaticTypeWarningCode.UNDEFINED_GETTER, 21, 8),
    ]);
  }

  test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle() async {
    await assertErrorsInCode(r'''
class A<K, V> {
  K element;
}
main(A<int> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 36, 6),
    ]);
  }

  test_undefinedGetter_wrongNumberOfTypeArguments_tooMany() async {
    await assertErrorsInCode(r'''
class A<E> {
  E element;
}
main(A<int,int> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 33, 10),
    ]);
  }

  test_undefinedGetter_wrongOfTypeArgument() async {
    await assertErrorsInCode(r'''
class A<E> {
  E element;
}
main(A<NoSuchType> a) {
  a.element.anyGetterExistsInDynamic;
}
''', [
      error(StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT, 35, 10),
    ]);
  }

  test_undefinedMethod_assignmentExpression() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  f(A a) {
    A a2 = new A();
    a += a2;
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 58, 2),
    ]);
  }

  test_undefinedMethod_ignoreTypePropagation() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
  }
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 85, 1),
    ]);
  }

  test_undefinedMethod_leastUpperBoundWithNull() async {
    await assertErrorsInCode('''
f(bool b, int i) => (b ? null : i).foo();
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 35, 3),
    ]);
  }

  test_undefinedMethod_ofNull() async {
    // TODO(scheglov) Track https://github.com/dart-lang/sdk/issues/28430 to
    // decide whether a warning should be reported here.
    await assertErrorsInCode(r'''
Null f(int x) => null;
main() {
  f(42).abs();
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_METHOD, 40, 3),
    ]);
  }

  test_undefinedMethodWithConstructor() async {
    await assertNoErrorsInCode(r'''
class C {
  C.m();
}
f() {
  C c = C.m();
}
''');
  }

  test_undefinedOperator_indexBoth() async {
    await assertErrorsInCode(r'''
class A {}
f(A a) {
  a[0]++;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 23, 3),
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 23, 3),
    ]);
  }

  test_undefinedOperator_indexGetter() async {
    await assertErrorsInCode(r'''
class A {}
f(A a) {
  a[0];
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 23, 3),
    ]);
  }

  test_undefinedOperator_indexSetter() async {
    await assertErrorsInCode(r'''
class A {}
f(A a) {
  a[0] = 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 23, 3),
    ]);
  }

  test_undefinedOperator_plus() async {
    await assertErrorsInCode(r'''
class A {}
f(A a) {
  a + 1;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 24, 1),
    ]);
  }

  test_undefinedOperator_postfixExpression() async {
    await assertErrorsInCode(r'''
class A {}
f(A a) {
  a++;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 23, 2),
    ]);
  }

  test_undefinedOperator_prefixExpression() async {
    await assertErrorsInCode(r'''
class A {}
f(A a) {
  ++a;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_OPERATOR, 22, 2),
    ]);
  }

  test_undefinedSetter() async {
    await assertErrorsInCode(r'''
class T {}
f(T e1) { e1.m = 0; }
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 24, 1),
    ]);
  }

  test_undefinedSetter_static() async {
    await assertErrorsInCode(r'''
class A {}
f() { A.B = 0;}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 19, 1),
    ]);
  }

  test_undefinedSetter_typeLiteral_cascadeTarget() async {
    await assertErrorsInCode(r'''
class T {
  static void set foo(_) {}
}
main() {
  T..foo = 42;
}
''', [
      error(StaticTypeWarningCode.UNDEFINED_SETTER, 54, 3),
    ]);
  }

  test_unqualifiedReferenceToNonLocalStaticMember_getter() async {
    await assertErrorsInCode(r'''
class A {
  static int get a => 0;
}
class B extends A {
  int b() {
    return a;
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          80,
          1),
    ]);
  }

  test_unqualifiedReferenceToNonLocalStaticMember_getter_invokeTarget() async {
    await assertErrorsInCode(r'''
class A {
  static int foo;
}

class B extends A {
  static bar() {
    foo.abs();
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          72,
          3),
    ]);
  }

  test_unqualifiedReferenceToNonLocalStaticMember_setter() async {
    await assertErrorsInCode(r'''
class A {
  static set a(x) {}
}
class B extends A {
  b(y) {
    a = y;
  }
}
''', [
      error(
          StaticTypeWarningCode
              .UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER,
          66,
          1),
    ]);
  }

  test_wrongNumberOfTypeArguments_class_tooFew() async {
    await assertErrorsInCode(r'''
class A<E, F> {}
A<A> a = null;
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 17, 4),
    ]);
  }

  test_wrongNumberOfTypeArguments_class_tooMany() async {
    await assertErrorsInCode(r'''
class A<E> {}
A<A, A> a = null;
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 14, 7),
    ]);
  }

  test_wrongNumberOfTypeArguments_classAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B<F extends num> = A<F> with M;
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 47, 4),
    ]);
  }

  test_wrongNumberOfTypeArguments_dynamic() async {
    await assertErrorsInCode(r'''
dynamic<int> v;
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 0, 12),
    ]);
  }

  test_wrongNumberOfTypeArguments_typeParameter() async {
    await assertErrorsInCode(r'''
class C<T> {
  T<int> f;
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 15, 6),
    ]);
  }

  test_wrongNumberOfTypeArguments_typeTest_tooFew() async {
    await assertErrorsInCode(r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 49, 4),
    ]);
  }

  test_wrongNumberOfTypeArguments_typeTest_tooMany() async {
    await assertErrorsInCode(r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
}
''', [
      error(StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS, 46, 7),
    ]);
  }

  test_yield_async_to_basic_type() async {
    await assertErrorsInCode('''
int f() async* {
  yield 3;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 3),
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 25, 1),
    ]);
  }

  test_yield_async_to_iterable() async {
    await assertErrorsInCode('''
Iterable<int> f() async* {
  yield 3;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE, 0, 13),
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 35, 1),
    ]);
  }

  test_yield_async_to_mistyped_stream() async {
    await assertErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
  yield "foo";
}
''', [
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 54, 5),
    ]);
  }

  test_yield_each_async_non_stream() async {
    await assertErrorsInCode('''
f() async* {
  yield* 0;
}
''', [
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 22, 1),
    ]);
  }

  test_yield_each_async_to_mistyped_stream() async {
    await assertErrorsInCode('''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
Stream<String> g() => null;
''', [
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 55, 3),
    ]);
  }

  test_yield_each_sync_non_iterable() async {
    await assertErrorsInCode('''
f() sync* {
  yield* 0;
}
''', [
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 21, 1),
    ]);
  }

  test_yield_each_sync_to_mistyped_iterable() async {
    await assertErrorsInCode('''
Iterable<int> f() sync* {
  yield* g();
}
Iterable<String> g() => null;
''', [
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 35, 3),
    ]);
  }

  test_yield_sync_to_basic_type() async {
    await assertErrorsInCode('''
int f() sync* {
  yield 3;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 0, 3),
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 24, 1),
    ]);
  }

  test_yield_sync_to_mistyped_iterable() async {
    await assertErrorsInCode('''
Iterable<int> f() sync* {
  yield "foo";
}
''', [
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 34, 5),
    ]);
  }

  test_yield_sync_to_stream() async {
    await assertErrorsInCode('''
import 'dart:async';
Stream<int> f() sync* {
  yield 3;
}
''', [
      error(StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE, 21, 11),
      error(StaticTypeWarningCode.YIELD_OF_INVALID_TYPE, 53, 1),
    ]);
  }
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest extends DriverResolutionTest {
  test_legalAsyncGeneratorReturnType_function_supertypeOfStream() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async* { yield 42; }
dynamic f2() async* { yield 42; }
Object f3() async* { yield 42; }
Stream f4() async* { yield 42; }
Stream<dynamic> f5() async* { yield 42; }
Stream<Object> f6() async* { yield 42; }
Stream<num> f7() async* { yield 42; }
Stream<int> f8() async* { yield 42; }
''');
  }

  test_legalAsyncReturnType_function_supertypeOfFuture() async {
    await assertNoErrorsInCode('''
import 'dart:async';
f() async { return 42; }
dynamic f2() async { return 42; }
Object f3() async { return 42; }
Future f4() async { return 42; }
Future<dynamic> f5() async { return 42; }
Future<Object> f6() async { return 42; }
Future<num> f7() async { return 42; }
Future<int> f8() async { return 42; }
''');
  }

  test_legalSyncGeneratorReturnType_function_supertypeOfIterable() async {
    await assertNoErrorsInCode('''
f() sync* { yield 42; }
dynamic f2() sync* { yield 42; }
Object f3() sync* { yield 42; }
Iterable f4() sync* { yield 42; }
Iterable<dynamic> f5() sync* { yield 42; }
Iterable<Object> f6() sync* { yield 42; }
Iterable<num> f7() sync* { yield 42; }
Iterable<int> f8() sync* { yield 42; }
''');
  }
}
