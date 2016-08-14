// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.static_type_warning_code_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart' show formatList;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'resolver_test_case.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(StaticTypeWarningCodeTest);
  runReflectiveTests(StrongModeStaticTypeWarningCodeTest);
}

@reflectiveTest
class StaticTypeWarningCodeTest extends ResolverTestCase {
  void fail_inaccessibleSetter() {
    // TODO(rnystrom): This doesn't look right.
    assertErrorsInCode(
        r'''
''',
        [StaticTypeWarningCode.INACCESSIBLE_SETTER]);
  }

  void fail_method_lookup_mixin_of_extends() {
    // See dartbug.com/25605
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    assertErrorsInUnverifiedCode(
        '''
class A { a() => null; }
class B {}
abstract class M extends A {}
class T = B with M; // Warning: B does not extend A
main() {
  new T().a(); // Warning: The method 'a' is not defined for the class 'T'
}
''',
        [
          // TODO(paulberry): when dartbug.com/25614 is fixed, add static warning
          // code for "B does not extend A".
          StaticTypeWarningCode.UNDEFINED_METHOD
        ]);
  }

  void fail_method_lookup_mixin_of_implements() {
    // See dartbug.com/25605
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    assertErrorsInUnverifiedCode(
        '''
class A { a() => null; }
class B {}
abstract class M implements A {}
class T = B with M; // Warning: Missing concrete implementation of 'A.a'
main() {
  new T().a(); // Warning: The method 'a' is not defined for the class 'T'
}
''',
        [
          StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE,
          StaticTypeWarningCode.UNDEFINED_METHOD
        ]);
  }

  void fail_method_lookup_mixin_of_mixin() {
    // See dartbug.com/25605
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    assertErrorsInUnverifiedCode(
        '''
class A {}
class B { b() => null; }
class C {}
class M extends A with B {}
class T = C with M;
main() {
  new T().b();
}
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void fail_method_lookup_mixin_of_mixin_application() {
    // See dartbug.com/25605
    resetWithOptions(new AnalysisOptionsImpl()..enableSuperMixins = true);
    assertErrorsInUnverifiedCode(
        '''
class A { a() => null; }
class B {}
class C {}
class M = A with B;
class T = C with M;
main() {
  new T().a();
}
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void fail_undefinedEnumConstant() {
    // We need a way to set the parseEnum flag in the parser to true.
    assertErrorsInCode(
        r'''
enum E { ONE }
E e() {
  return E.TWO;
}''',
        [StaticTypeWarningCode.UNDEFINED_ENUM_CONSTANT]);
  }

  void test_ambiguousImport_function() {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
g() { return f(); }''');
    addNamedSource(
        "/lib1.dart",
        r'''
library lib1;
f() {}''');
    addNamedSource(
        "/lib2.dart",
        r'''
library lib2;
f() {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_assert_message_suppresses_type_promotion() {
    // If a variable is assigned to inside the expression for an assert
    // message, type promotion should be suppressed, just as it would be if the
    // assignment occurred outside an assert statement.  (Note that it is a
    // dubious practice for the computation of an assert message to have side
    // effects, since it is only evaluated if the assert fails).
    resetWithOptions(new AnalysisOptionsImpl()..enableAssertMessage = true);
    assertErrorsInCode(
        '''
class C {
  void foo() {}
}

f(Object x) {
  if (x is C) {
    x.foo();
    assert(true, () { x = new C(); return 'msg'; }());
  }
}
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
    // Do not verify since `x.foo()` fails to resolve.
  }

  void test_await_flattened() {
    assertErrorsInCode(
        '''
import 'dart:async';
Future<Future<int>> ffi() => null;
f() async {
  Future<int> b = await ffi(); // Warning: int not assignable to Future<int>
}
''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_await_simple() {
    assertErrorsInCode(
        '''
import 'dart:async';
Future<int> fi() => null;
f() async {
  String a = await fi(); // Warning: int not assignable to String
}
''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_awaitForIn_declaredVariableRightType() {
    assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  await for (int i in stream) {}
}
''');
  }

  void test_awaitForIn_declaredVariableWrongType() {
    assertErrorsInCode(
        '''
import 'dart:async';
f() async {
  Stream<String> stream;
  await for (int i in stream) {}
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  void test_awaitForIn_downcast() {
    assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<num> stream;
  await for (int i in stream) {}
}
''');
  }

  void test_awaitForIn_dynamicStream() {
    assertNoErrorsInCode('''
f() async {
  dynamic stream;
  await for (int i in stream) {}
}
''');
  }

  void test_awaitForIn_dynamicVariable() {
    assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  await for (var i in stream) {}
}
''');
  }

  void test_awaitForIn_existingVariableRightType() {
    assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  int i;
  await for (i in stream) {}
}
''');
  }

  void test_awaitForIn_existingVariableWrongType() {
    assertErrorsInCode(
        '''
import 'dart:async';
f() async {
  Stream<String> stream;
  int i;
  await for (i in stream) {}
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  void test_awaitForIn_notStream() {
    assertErrorsInCode(
        '''
f() async {
  await for (var i in true) {}
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE]);
  }

  void test_awaitForIn_streamOfDynamic() {
    assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream stream;
  await for (int i in stream) {}
}
''');
  }

  void test_awaitForIn_upcast() {
    assertNoErrorsInCode('''
import 'dart:async';
f() async {
  Stream<int> stream;
  await for (num i in stream) {}
}
''');
  }

  void test_bug21912() {
    assertErrorsInCode(
        '''
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
''',
        [
          StaticTypeWarningCode.INVALID_ASSIGNMENT,
          StaticTypeWarningCode.INVALID_ASSIGNMENT
        ]);
  }

  void test_expectedOneListTypeArgument() {
    assertErrorsInCode(
        r'''
main() {
  <int, int> [];
}''',
        [StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS]);
  }

  void test_expectedTwoMapTypeArguments_one() {
    assertErrorsInCode(
        r'''
main() {
  <int> {};
}''',
        [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS]);
  }

  void test_expectedTwoMapTypeArguments_three() {
    assertErrorsInCode(
        r'''
main() {
  <int, int, int> {};
}''',
        [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS]);
  }

  void test_forIn_declaredVariableRightType() {
    assertNoErrorsInCode('''
f() {
  for (int i in <int>[]) {}
}
''');
  }

  void test_forIn_declaredVariableWrongType() {
    assertErrorsInCode(
        '''
f() {
  for (int i in <String>[]) {}
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  void test_forIn_downcast() {
    assertNoErrorsInCode('''
f() {
  for (int i in <num>[]) {}
}
''');
  }

  void test_forIn_dynamic() {
    assertNoErrorsInCode('''
f() {
  dynamic d; // Could be [].
  for (var i in d) {}
}
''');
  }

  void test_forIn_dynamicIterable() {
    assertNoErrorsInCode('''
f() {
  dynamic iterable;
  for (int i in iterable) {}
}
''');
  }

  void test_forIn_dynamicVariable() {
    assertNoErrorsInCode('''
f() {
  for (var i in <int>[]) {}
}
''');
  }

  void test_forIn_existingVariableRightType() {
    assertNoErrorsInCode('''
f() {
  int i;
  for (i in <int>[]) {}
}
''');
  }

  void test_forIn_existingVariableWrongType() {
    assertErrorsInCode(
        '''
f() {
  int i;
  for (i in <String>[]) {}
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  void test_forIn_iterableOfDynamic() {
    assertNoErrorsInCode('''
f() {
  for (int i in []) {}
}
''');
  }

  void test_forIn_notIterable() {
    assertErrorsInCode(
        '''
f() {
  for (var i in true) {}
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE]);
  }

  void test_forIn_object() {
    assertNoErrorsInCode('''
f() {
  Object o; // Could be [].
  for (var i in o) {}
}
''');
  }

  void test_forIn_typeBoundBad() {
    assertErrorsInCode(
        '''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
  }
}
''',
        [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  void test_forIn_typeBoundGood() {
    assertNoErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (var i in iterable) {}
  }
}
''');
  }

  void test_forIn_upcast() {
    assertNoErrorsInCode('''
f() {
  for (num i in <int>[]) {}
}
''');
  }

  void test_illegalAsyncGeneratorReturnType_function_nonStream() {
    assertErrorsInCode(
        '''
int f() async* {}
''',
        [StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalAsyncGeneratorReturnType_function_subtypeOfStream() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        '''
import 'dart:async';
abstract class SubStream<T> implements Stream<T> {}
SubStream<int> f() async* {}
''',
        [StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalAsyncGeneratorReturnType_method_nonStream() {
    assertErrorsInCode(
        '''
class C {
  int f() async* {}
}
''',
        [StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalAsyncGeneratorReturnType_method_subtypeOfStream() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        '''
import 'dart:async';
abstract class SubStream<T> implements Stream<T> {}
class C {
  SubStream<int> f() async* {}
}
''',
        [StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalAsyncReturnType_function_nonFuture() {
    assertErrorsInCode(
        '''
int f() async {}
''',
        [
          StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE,
          HintCode.MISSING_RETURN
        ]);
  }

  void test_illegalAsyncReturnType_function_subtypeOfFuture() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        '''
import 'dart:async';
abstract class SubFuture<T> implements Future<T> {}
SubFuture<int> f() async {
  return 0;
}
''',
        [StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE]);
  }

  void test_illegalAsyncReturnType_method_nonFuture() {
    assertErrorsInCode(
        '''
class C {
  int m() async {}
}
''',
        [
          StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE,
          HintCode.MISSING_RETURN
        ]);
  }

  void test_illegalAsyncReturnType_method_subtypeOfFuture() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        '''
import 'dart:async';
abstract class SubFuture<T> implements Future<T> {}
class C {
  SubFuture<int> m() async {
    return 0;
  }
}
''',
        [StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE]);
  }

  void test_illegalSyncGeneratorReturnType_function_nonIterator() {
    assertErrorsInCode(
        '''
int f() sync* {}
''',
        [StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalSyncGeneratorReturnType_function_subclassOfIterator() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        '''
abstract class SubIterator<T> implements Iterator<T> {}
SubIterator<int> f() sync* {}
''',
        [StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalSyncGeneratorReturnType_method_nonIterator() {
    assertErrorsInCode(
        '''
class C {
  int f() sync* {}
}
''',
        [StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_illegalSyncGeneratorReturnType_method_subclassOfIterator() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        '''
abstract class SubIterator<T> implements Iterator<T> {}
class C {
  SubIterator<int> f() sync* {}
}
''',
        [StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE]);
  }

  void test_inconsistentMethodInheritance_paramCount() {
    assertErrorsInCode(
        r'''
abstract class A {
  int x();
}
abstract class B {
  int x(int y);
}
class C implements A, B {
}''',
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }

  void test_inconsistentMethodInheritance_paramType() {
    assertErrorsInCode(
        r'''
abstract class A {
  x(int i);
}
abstract class B {
  x(String s);
}
abstract class C implements A, B {}
''',
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }

  void test_inconsistentMethodInheritance_returnType() {
    assertErrorsInCode(
        r'''
abstract class A {
  int x();
}
abstract class B {
  String x();
}
abstract class C implements A, B {}
''',
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }

  void test_instanceAccessToStaticMember_method_invocation() {
    assertErrorsInCode(
        r'''
class A {
  static m() {}
}
main(A a) {
  a.m();
}''',
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
  }

  void test_instanceAccessToStaticMember_method_reference() {
    assertErrorsInCode(
        r'''
class A {
  static m() {}
}
main(A a) {
  a.m;
}''',
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
  }

  void test_instanceAccessToStaticMember_propertyAccess_field() {
    assertErrorsInCode(
        r'''
class A {
  static var f;
}
main(A a) {
  a.f;
}''',
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
  }

  void test_instanceAccessToStaticMember_propertyAccess_getter() {
    assertErrorsInCode(
        r'''
class A {
  static get f => 42;
}
main(A a) {
  a.f;
}''',
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
  }

  void test_instanceAccessToStaticMember_propertyAccess_setter() {
    assertErrorsInCode(
        r'''
class A {
  static set f(x) {}
}
main(A a) {
  a.f = 42;
}''',
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
  }

  void test_invalidAssignment_compoundAssignment() {
    assertErrorsInCode(
        r'''
class byte {
  int _value;
  byte(this._value);
  int operator +(int val) { return 0; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_defaultValue_named() {
    assertErrorsInCode(
        r'''
f({String x: 0}) {
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_defaultValue_optional() {
    assertErrorsInCode(
        r'''
f([String x = 0]) {
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_dynamic() {
    assertErrorsInCode(
        r'''
main() {
  dynamic = 1;
}
''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_functionExpressionInvocation() {
    assertErrorsInCode(
        '''
main() {
  String x = (() => 5)();
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_ifNullAssignment() {
    assertErrorsInCode(
        '''
void f(int i) {
  double d;
  d ??= i;
}
''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_instanceVariable() {
    assertErrorsInCode(
        r'''
class A {
  int x;
}
f() {
  A a;
  a.x = '0';
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_localVariable() {
    assertErrorsInCode(
        r'''
f() {
  int x;
  x = '0';
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_regressionInIssue18468Fix() {
    // https://code.google.com/p/dart/issues/detail?id=18628
    assertErrorsInCode(
        r'''
class C<T> {
  T t = int;
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_staticVariable() {
    assertErrorsInCode(
        r'''
class A {
  static int x;
}
f() {
  A.x = '0';
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_topLevelVariableDeclaration() {
    assertErrorsInCode(
        "int x = 'string';", [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_typeParameter() {
    // 14221
    assertErrorsInCode(
        r'''
class B<T> {
  T value;
  void test(num n) {
    value = n;
  }
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invalidAssignment_variableDeclaration() {
    assertErrorsInCode(
        r'''
class A {
  int x = 'string';
}''',
        [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
  }

  void test_invocationOfNonFunction_class() {
    assertErrorsInCode(
        r'''
class A {
  void m() {
    A();
  }
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }

  void test_invocationOfNonFunction_localGenericFunction() {
    // Objects having a specific function type may be invoked, but objects
    // having type Function may not, because type Function lacks a call method
    // (this is because it is impossible to know what signature the call should
    // have).
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableStrictCallChecks = true;
    resetWithOptions(options);
    assertErrorsInCode(
        '''
f(Function f) {
  return f();
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }

  void test_invocationOfNonFunction_localObject() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableStrictCallChecks = true;
    resetWithOptions(options);
    assertErrorsInCode(
        '''
f(Object o) {
  return o();
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }

  void test_invocationOfNonFunction_localVariable() {
    assertErrorsInCode(
        r'''
f() {
  int x;
  return x();
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }

  void test_invocationOfNonFunction_ordinaryInvocation() {
    assertErrorsInCode(
        r'''
class A {
  static int x;
}
class B {
  m() {
    A.x();
  }
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    // A call to verify(source) fails as A.x() cannot be resolved.
  }

  void test_invocationOfNonFunction_staticInvocation() {
    assertErrorsInCode(
        r'''
class A {
  static int get g => 0;
  f() {
    A.g();
  }
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    // A call to verify(source) fails as g() cannot be resolved.
  }

  void test_invocationOfNonFunction_superExpression() {
    assertErrorsInCode(
        r'''
class A {
  int get g => 0;
}
class B extends A {
  m() {
    var v = super.g();
  }
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }

  void test_invocationOfNonFunctionExpression_literal() {
    assertErrorsInCode(
        r'''
f() {
  3(5);
}''',
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION]);
  }

  void test_nonBoolCondition_conditional() {
    assertErrorsInCode("f() { return 3 ? 2 : 1; }",
        [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  void test_nonBoolCondition_do() {
    assertErrorsInCode(
        r'''
f() {
  do {} while (3);
}''',
        [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  // https://github.com/dart-lang/sdk/issues/24713
  void test_nonBoolCondition_for() {
    assertErrorsInCode(
        r'''
f() {
  for (;3;) {}
}''',
        [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  void test_nonBoolCondition_if() {
    assertErrorsInCode(
        r'''
f() {
  if (3) return 2; else return 1;
}''',
        [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  void test_nonBoolCondition_while() {
    assertErrorsInCode(
        r'''
f() {
  while (3) {}
}''',
        [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  void test_nonBoolExpression_functionType() {
    assertErrorsInCode(
        r'''
int makeAssertion() => 1;
f() {
  assert(makeAssertion);
}''',
        [StaticTypeWarningCode.NON_BOOL_EXPRESSION]);
  }

  void test_nonBoolExpression_interfaceType() {
    assertErrorsInCode(
        r'''
f() {
  assert(0);
}''',
        [StaticTypeWarningCode.NON_BOOL_EXPRESSION]);
  }

  void test_nonBoolNegationExpression() {
    assertErrorsInCode(
        r'''
f() {
  !42;
}''',
        [StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION]);
  }

  void test_nonBoolOperand_and_left() {
    assertErrorsInCode(
        r'''
bool f(int left, bool right) {
  return left && right;
}''',
        [StaticTypeWarningCode.NON_BOOL_OPERAND]);
  }

  void test_nonBoolOperand_and_right() {
    assertErrorsInCode(
        r'''
bool f(bool left, String right) {
  return left && right;
}''',
        [StaticTypeWarningCode.NON_BOOL_OPERAND]);
  }

  void test_nonBoolOperand_or_left() {
    assertErrorsInCode(
        r'''
bool f(List<int> left, bool right) {
  return left || right;
}''',
        [StaticTypeWarningCode.NON_BOOL_OPERAND]);
  }

  void test_nonBoolOperand_or_right() {
    assertErrorsInCode(
        r'''
bool f(bool left, double right) {
  return left || right;
}''',
        [StaticTypeWarningCode.NON_BOOL_OPERAND]);
  }

  void test_nonTypeAsTypeArgument_notAType() {
    assertErrorsInCode(
        r'''
int A;
class B<E> {}
f(B<A> b) {}''',
        [StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
  }

  void test_nonTypeAsTypeArgument_undefinedIdentifier() {
    assertErrorsInCode(
        r'''
class B<E> {}
f(B<A> b) {}''',
        [StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
  }

  void test_returnOfInvalidType_async_future_int_mismatches_future_null() {
    assertErrorsInCode(
        '''
import 'dart:async';
Future<Null> f() async {
  return 5;
}
''',
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_async_future_int_mismatches_future_string() {
    assertErrorsInCode(
        '''
import 'dart:async';
Future<String> f() async {
  return 5;
}
''',
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_async_future_int_mismatches_int() {
    assertErrorsInCode(
        '''
int f() async {
  return 5;
}
''',
        [
          StaticTypeWarningCode.RETURN_OF_INVALID_TYPE,
          StaticTypeWarningCode.ILLEGAL_ASYNC_RETURN_TYPE
        ]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_function() {
    assertErrorsInCode(
        "int f() => '0';", [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_getter() {
    assertErrorsInCode(
        "int get g => '0';", [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_localFunction() {
    assertErrorsInCode(
        r'''
class A {
  String m() {
    int f() => '0';
    return '0';
  }
}''',
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_method() {
    assertErrorsInCode(
        r'''
class A {
  int f() => '0';
}''',
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_void() {
    assertErrorsInCode(
        "void f() => 42;", [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_function() {
    assertErrorsInCode("int f() { return '0'; }",
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_getter() {
    assertErrorsInCode("int get g { return '0'; }",
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_localFunction() {
    assertErrorsInCode(
        r'''
class A {
  String m() {
    int f() { return '0'; }
    return '0';
  }
}''',
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_method() {
    assertErrorsInCode(
        r'''
class A {
  int f() { return '0'; }
}''',
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_returnOfInvalidType_not_issued_for_valid_generic_return() {
    assertNoErrorsInCode(r'''
abstract class F<T, U>  {
  U get value;
}

abstract class G<T> {
  T test(F<int, T> arg) => arg.value;
}

abstract class H<S> {
  S test(F<int, S> arg) => arg.value;
}

void main() { }''');
  }

  void test_returnOfInvalidType_void() {
    assertErrorsInCode("void f() { return 42; }",
        [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
  }

  void test_typeArgumentNotMatchingBounds_classTypeAlias() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D = G<B> with C;
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_extends() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
class C extends G<B>{}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_extends_regressionInIssue18468Fix() {
    // https://code.google.com/p/dart/issues/detail?id=18628
    assertErrorsInCode(
        r'''
class X<T extends Type> {}
class Y<U> extends X<U> {}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_fieldFormalParameter() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  var f;
  C(G<B> this.f) {}
}''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_functionReturnType() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
G<B> f() { return null; }
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_functionTypeAlias() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
typedef G<B> f();
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_functionTypedFormalParameter() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> h()) {}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_implements() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
class C implements G<B>{}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_is() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
var b = 1 is G<B>;
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_methodInvocation_localFunction() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        r'''
class Point<T extends num> {
  Point(T x, T y);
}

main() {
  Point/*<T>*/ f/*<T extends num>*/(num/*=T*/ x, num/*=T*/ y) {
    return new Point/*<T>*/(x, y);
  }
  print(f/*<String>*/('hello', 'world'));
}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_methodInvocation_method() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        r'''
class Point<T extends num> {
  Point(T x, T y);
}

class PointFactory {
  Point/*<T>*/ point/*<T extends num>*/(num/*=T*/ x, num/*=T*/ y) {
    return new Point/*<T>*/(x, y);
  }
}

f(PointFactory factory) {
  print(factory.point/*<String>*/('hello', 'world'));
}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_methodInvocation_topLevelFunction() {
    resetWithOptions(new AnalysisOptionsImpl()..strongMode = true);
    assertErrorsInCode(
        r'''
class Point<T extends num> {
  Point(T x, T y);
}

Point/*<T>*/ f/*<T extends num>*/(num/*=T*/ x, num/*=T*/ y) {
  return new Point/*<T>*/(x, y);
}

main() {
  print(f/*<String>*/('hello', 'world'));
}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_methodReturnType() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  G<B> m() { return null; }
}''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_new() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
f() { return new G<B>(); }
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_new_superTypeOfUpperBound() {
    assertErrorsInCode(
        r'''
class A {}
class B extends A {}
class C extends B {}
class G<E extends B> {}
f() { return new G<A>(); }
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void fail_typeArgumentNotMatchingBounds_ofFunctionTypeAlias() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
typedef F<T extends A>();
F<B> fff;
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_parameter() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> g) {}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_redirectingConstructor() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class X<T extends A> {
  X(int x, int y) {}
  factory X.name(int x, int y) = X<B>;
}''',
        [
          StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
          StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE
        ]);
  }

  void test_typeArgumentNotMatchingBounds_typeArgumentList() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class C<E> {}
class D<E extends A> {}
C<D<B>> Var;
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_typeParameter() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D<F extends G<B>> {}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_variableDeclaration() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
G<B> g;
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeArgumentNotMatchingBounds_with() {
    assertErrorsInCode(
        r'''
class A {}
class B {}
class G<E extends A> {}
class C extends Object with G<B>{}
''',
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  void test_typeParameterSupertypeOfItsBound() {
    assertErrorsInCode(
        r'''
class A<T extends T> {
}
''',
        [StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND]);
  }

  void
      test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_mutated() {
    assertErrorsInUnverifiedCode(
        r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
  p = 0;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_booleanAnd_useInRight_mutatedInLeft() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  ((p is String) && ((p = 42) == 42)) && p.length != 0;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_booleanAnd_useInRight_mutatedInRight() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  (p is String) && (((p = 42) == 42) && p.length != 0);
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void
      test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_after() {
    assertErrorsInUnverifiedCode(
        r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
  p = 42;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void
      test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_before() {
    assertErrorsInUnverifiedCode(
        r'''
callMe(f()) { f(); }
main(Object p) {
  p = 42;
  p is String ? callMe(() { p.length; }) : 0;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_conditional_useInThen_hasAssignment() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  p is String ? (p.length + (p = 42)) : 0;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_accessedInClosure_hasAssignment() {
    assertErrorsInUnverifiedCode(
        r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
  p = 0;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_and_right_hasAssignment() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  if (p is String && (p = null) == null) {
    p.length;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_extends_notMoreSpecific_dynamic() {
    assertErrorsInUnverifiedCode(
        r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_extends_notMoreSpecific_notMoreSpecificTypeArg() {
    assertErrorsInUnverifiedCode(
        r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<int>) {
    p.b;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_after() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  if (p is String) {
    p.length;
    p = 0;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_before() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  if (p is String) {
    p = 0;
    p.length;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_anonymous_after() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  () {p = 0;};
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_anonymous_before() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  () {p = 0;};
  if (p is String) {
    p.length;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_function_after() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  f() {p = 0;};
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_function_before() {
    assertErrorsInUnverifiedCode(
        r'''
main(Object p) {
  f() {p = 0;};
  if (p is String) {
    p.length;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_implements_notMoreSpecific_dynamic() {
    assertErrorsInUnverifiedCode(
        r'''
class V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_with_notMoreSpecific_dynamic() {
    assertErrorsInUnverifiedCode(
        r'''
class V {}
class A<T> {}
class B<S> extends Object with A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedFunction() {
    assertErrorsInCode(
        r'''
void f() {
  g();
}''',
        [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedFunction_inCatch() {
    assertErrorsInCode(
        r'''
void f() {
  try {
  } on Object {
    g();
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedFunction_inImportedLib() {
    Source source = addSource(r'''
import 'lib.dart' as f;
main() { return f.g(); }''');
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
h() {}''');
    computeLibrarySourceErrors(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedGetter() {
    assertErrorsInUnverifiedCode(
        r'''
class T {}
f(T e) { return e.m; }''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_generic_function_call() {
    // Objects having a specific function type have a call() method, but
    // objects having type Function do not (this is because it is impossible to
    // know what signature the call should have).
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableStrictCallChecks = true;
    resetWithOptions(options);
    assertErrorsInUnverifiedCode(
        '''
f(Function f) {
  return f.call;
}
''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_object_call() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableStrictCallChecks = true;
    resetWithOptions(options);
    assertErrorsInUnverifiedCode(
        '''
f(Object o) {
  return o.call;
}
''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_proxy_annotation_fakeProxy() {
    assertErrorsInCode(
        r'''
library L;
class Fake {
  const Fake();
}
const proxy = const Fake();
@proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_static() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
var a = A.B;''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_typeLiteral_cascadeTarget() {
    assertErrorsInCode(
        r'''
class T {
  static int get foo => 42;
}
main() {
  T..foo;
}''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_typeLiteral_conditionalAccess() {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance getters of Type.
    assertErrorsInCode(
        '''
class A {}
f() => A?.hashCode;
''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_void() {
    assertErrorsInCode(
        r'''
class T {
  void m() {}
}
f(T e) { return e.m().f; }''',
        [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle() {
    assertErrorsInCode(
        r'''
class A<K, V> {
  K element;
}
main(A<int> a) {
  a.element.anyGetterExistsInDynamic;
}''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_undefinedGetter_wrongNumberOfTypeArguments_tooMany() {
    assertErrorsInCode(
        r'''
class A<E> {
  E element;
}
main(A<int,int> a) {
  a.element.anyGetterExistsInDynamic;
}''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_undefinedGetter_wrongOfTypeArgument() {
    assertErrorsInCode(
        r'''
class A<E> {
  E element;
}
main(A<NoSuchType> a) {
  a.element.anyGetterExistsInDynamic;
}''',
        [StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
  }

  void test_undefinedMethod() {
    assertErrorsInCode(
        r'''
class A {
  void m() {
    n();
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_assignmentExpression() {
    assertErrorsInCode(
        r'''
class A {}
class B {
  f(A a) {
    A a2 = new A();
    a += a2;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_generic_function_call() {
    // Objects having a specific function type have a call() method, but
    // objects having type Function do not (this is because it is impossible to
    // know what signature the call should have).
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableStrictCallChecks = true;
    resetWithOptions(options);
    assertErrorsInCode(
        '''
f(Function f) {
  f.call();
}
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_ignoreTypePropagation() {
    assertErrorsInCode(
        r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_leastUpperBoundWithNull() {
    assertErrorsInCode('f(bool b, int i) => (b ? null : i).foo();',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_object_call() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableStrictCallChecks = true;
    resetWithOptions(options);
    assertErrorsInCode(
        '''
f(Object o) {
  o.call();
}
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_private() {
    addNamedSource(
        "/lib.dart",
        r'''
library lib;
class A {
  _foo() {}
}''');
    assertErrorsInCode(
        r'''
import 'lib.dart';
class B extends A {
  test() {
    _foo();
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_proxy_annotation_fakeProxy() {
    assertErrorsInCode(
        r'''
library L;
class Fake {
  const Fake();
}
const proxy = const Fake();
@proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo();
}''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_typeLiteral_cascadeTarget() {
    assertErrorsInCode(
        '''
class T {
  static void foo() {}
}
main() {
  T..foo();
}
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_typeLiteral_conditionalAccess() {
    // When applied to a type literal, the conditional access operator '?.'
    // cannot be used to access instance methods of Type.
    assertErrorsInCode(
        '''
class A {}
f() => A?.toString();
''',
        [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethodWithConstructor() {
    assertErrorsInCode(
        r'''
class C {
  C.m();
}
f() {
  C c = C.m();
}''',
        [StaticTypeWarningCode.UNDEFINED_METHOD_WITH_CONSTRUCTOR]);
  }

  void test_undefinedOperator_indexBoth() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
f(A a) {
  a[0]++;
}''',
        [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexGetter() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
f(A a) {
  a[0];
}''',
        [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexSetter() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
f(A a) {
  a[0] = 1;
}''',
        [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_plus() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
f(A a) {
  a + 1;
}''',
        [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_postfixExpression() {
    assertErrorsInCode(
        r'''
class A {}
f(A a) {
  a++;
}''',
        [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_prefixExpression() {
    assertErrorsInCode(
        r'''
class A {}
f(A a) {
  ++a;
}''',
        [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedSetter() {
    assertErrorsInUnverifiedCode(
        r'''
class T {}
f(T e1) { e1.m = 0; }''',
        [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_static() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
f() { A.B = 0;}''',
        [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_typeLiteral_cascadeTarget() {
    assertErrorsInCode(
        r'''
class T {
  static void set foo(_) {}
}
main() {
  T..foo = 42;
}''',
        [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_void() {
    assertErrorsInCode(
        r'''
class T {
  void m() {}
}
f(T e) { e.m().f = 0; }''',
        [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSuperGetter() {
    assertErrorsInCode(
        r'''
class A {}
class B extends A {
  get g {
    return super.g;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_GETTER]);
  }

  void test_undefinedSuperMethod() {
    assertErrorsInCode(
        r'''
class A {}
class B extends A {
  m() { return super.m(); }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);
  }

  void test_undefinedSuperOperator_binaryExpression() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
class B extends A {
  operator +(value) {
    return super + value;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  void test_undefinedSuperOperator_indexBoth() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index]++;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  void test_undefinedSuperOperator_indexGetter() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
class B extends A {
  operator [](index) {
    return super[index + 1];
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  void test_undefinedSuperOperator_indexSetter() {
    assertErrorsInUnverifiedCode(
        r'''
class A {}
class B extends A {
  operator []=(index, value) {
    return super[index] = 0;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR]);
  }

  void test_undefinedSuperSetter() {
    assertErrorsInCode(
        r'''
class A {}
class B extends A {
  f() {
    super.m = 0;
  }
}''',
        [StaticTypeWarningCode.UNDEFINED_SUPER_SETTER]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_getter() {
    assertErrorsInCode(
        r'''
class A {
  static int get a => 0;
}
class B extends A {
  int b() {
    return a;
  }
}''',
        [
          StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER
        ]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_method() {
    assertErrorsInCode(
        r'''
class A {
  static void a() {}
}
class B extends A {
  void b() {
    a();
  }
}''',
        [
          StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER
        ]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_setter() {
    assertErrorsInCode(
        r'''
class A {
  static set a(x) {}
}
class B extends A {
  b(y) {
    a = y;
  }
}''',
        [
          StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER
        ]);
  }

  void test_wrongNumberOfTypeArguments_classAlias() {
    assertErrorsInCode(
        r'''
class A {}
class M {}
class B<F extends num> = A<F> with M;''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_wrongNumberOfTypeArguments_tooFew() {
    assertErrorsInCode(
        r'''
class A<E, F> {}
A<A> a = null;''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_wrongNumberOfTypeArguments_tooMany() {
    assertErrorsInCode(
        r'''
class A<E> {}
A<A, A> a = null;''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_wrongNumberOfTypeArguments_typeTest_tooFew() {
    assertErrorsInCode(
        r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
}''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_wrongNumberOfTypeArguments_typeTest_tooMany() {
    assertErrorsInCode(
        r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
}''',
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
  }

  void test_yield_async_to_basic_type() {
    assertErrorsInCode(
        '''
int f() async* {
  yield 3;
}
''',
        [
          StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
          StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE
        ]);
  }

  void test_yield_async_to_iterable() {
    assertErrorsInCode(
        '''
Iterable<int> f() async* {
  yield 3;
}
''',
        [
          StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
          StaticTypeWarningCode.ILLEGAL_ASYNC_GENERATOR_RETURN_TYPE
        ]);
  }

  void test_yield_async_to_mistyped_stream() {
    assertErrorsInCode(
        '''
import 'dart:async';
Stream<int> f() async* {
  yield "foo";
}
''',
        [StaticTypeWarningCode.YIELD_OF_INVALID_TYPE]);
  }

  void test_yield_each_async_non_stream() {
    assertErrorsInCode(
        '''
f() async* {
  yield* 0;
}
''',
        [StaticTypeWarningCode.YIELD_OF_INVALID_TYPE]);
  }

  void test_yield_each_async_to_mistyped_stream() {
    assertErrorsInCode(
        '''
import 'dart:async';
Stream<int> f() async* {
  yield* g();
}
Stream<String> g() => null;
''',
        [StaticTypeWarningCode.YIELD_OF_INVALID_TYPE]);
  }

  void test_yield_each_sync_non_iterable() {
    assertErrorsInCode(
        '''
f() sync* {
  yield* 0;
}
''',
        [StaticTypeWarningCode.YIELD_OF_INVALID_TYPE]);
  }

  void test_yield_each_sync_to_mistyped_iterable() {
    assertErrorsInCode(
        '''
Iterable<int> f() sync* {
  yield* g();
}
Iterable<String> g() => null;
''',
        [StaticTypeWarningCode.YIELD_OF_INVALID_TYPE]);
  }

  void test_yield_sync_to_basic_type() {
    assertErrorsInCode(
        '''
int f() sync* {
  yield 3;
}
''',
        [
          StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
          StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
        ]);
  }

  void test_yield_sync_to_mistyped_iterable() {
    assertErrorsInCode(
        '''
Iterable<int> f() sync* {
  yield "foo";
}
''',
        [StaticTypeWarningCode.YIELD_OF_INVALID_TYPE]);
  }

  void test_yield_sync_to_stream() {
    assertErrorsInCode(
        '''
import 'dart:async';
Stream<int> f() sync* {
  yield 3;
}
''',
        [
          StaticTypeWarningCode.YIELD_OF_INVALID_TYPE,
          StaticTypeWarningCode.ILLEGAL_SYNC_GENERATOR_RETURN_TYPE
        ]);
  }
}

@reflectiveTest
class StrongModeStaticTypeWarningCodeTest extends ResolverTestCase {
  void setUp() {
    super.setUp();
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.strongMode = true;
    resetWithOptions(options);
  }

  void test_genericMethodWrongNumberOfTypeArguments() {
    Source source = addSource('''
f() {}
main() {
  f/*<int>*/();
}
''');
    computeLibrarySourceErrors(source);
    assertErrors(
        source, [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    for (AnalysisError error in analysisContext2.computeErrors(source)) {
      if (error.errorCode ==
          StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS) {
        expect(error.message,
            formatList(error.errorCode.message, ['() → dynamic', 0, 1]));
      }
    }
    verify([source]);
  }

  void test_legalAsyncGeneratorReturnType_function_supertypeOfStream() {
    assertErrorsInCode(
        '''
import 'dart:async';
f() async* { yield 42; }
dynamic f2() async* { yield 42; }
Object f3() async* { yield 42; }
Stream f4() async* { yield 42; }
Stream<dynamic> f5() async* { yield 42; }
Stream<Object> f6() async* { yield 42; }
Stream<num> f7() async* { yield 42; }
Stream<int> f8() async* { yield 42; }
''',
        []);
  }

  void test_legalAsyncReturnType_function_supertypeOfFuture() {
    assertErrorsInCode(
        '''
import 'dart:async';
f() async { return 42; }
dynamic f2() async { return 42; }
Object f3() async { return 42; }
Future f4() async { return 42; }
Future<dynamic> f5() async { return 42; }
Future<Object> f6() async { return 42; }
Future<num> f7() async { return 42; }
Future<int> f8() async { return 42; }
''',
        []);
  }

  void test_legalSyncGeneratorReturnType_function_supertypeOfIterable() {
    assertErrorsInCode(
        '''
f() sync* { yield 42; }
dynamic f2() sync* { yield 42; }
Object f3() sync* { yield 42; }
Iterable f4() sync* { yield 42; }
Iterable<dynamic> f5() sync* { yield 42; }
Iterable<Object> f6() sync* { yield 42; }
Iterable<num> f7() sync* { yield 42; }
Iterable<int> f8() sync* { yield 42; }
''',
        []);
  }
}
