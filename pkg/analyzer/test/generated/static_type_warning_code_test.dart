// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.static_type_warning_code_test;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'resolver_test.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(StaticTypeWarningCodeTest);
}

class StaticTypeWarningCodeTest extends ResolverTestCase {
  void fail_inaccessibleSetter() {
    Source source = addSource(r'''
''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INACCESSIBLE_SETTER]);
    verify([source]);
  }

  void fail_undefinedEnumConstant() {
    // We need a way to set the parseEnum flag in the parser to true.
    Source source = addSource(r'''
enum E { ONE }
E e() {
  return E.TWO;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_ENUM_CONSTANT]);
    verify([source]);
  }

  void test_ambiguousImport_function() {
    Source source = addSource(r'''
import 'lib1.dart';
import 'lib2.dart';
g() { return f(); }''');
    addNamedSource("/lib1.dart", r'''
library lib1;
f() {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
f() {}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.AMBIGUOUS_IMPORT]);
  }

  void test_expectedOneListTypeArgument() {
    Source source = addSource(r'''
main() {
  <int, int> [];
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_expectedTwoMapTypeArguments_one() {
    Source source = addSource(r'''
main() {
  <int> {};
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_expectedTwoMapTypeArguments_three() {
    Source source = addSource(r'''
main() {
  <int, int, int> {};
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_paramCount() {
    Source source = addSource(r'''
abstract class A {
  int x();
}
abstract class B {
  int x(int y);
}
class C implements A, B {
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_paramType() {
    Source source = addSource(r'''
abstract class A {
  x(int i);
}
abstract class B {
  x(String s);
}
abstract class C implements A, B {}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }

  void test_inconsistentMethodInheritance_returnType() {
    Source source = addSource(r'''
abstract class A {
  int x();
}
abstract class B {
  String x();
}
abstract class C implements A, B {}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_method_invocation() {
    Source source = addSource(r'''
class A {
  static m() {}
}
main(A a) {
  a.m();
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_method_reference() {
    Source source = addSource(r'''
class A {
  static m() {}
}
main(A a) {
  a.m;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_propertyAccess_field() {
    Source source = addSource(r'''
class A {
  static var f;
}
main(A a) {
  a.f;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_propertyAccess_getter() {
    Source source = addSource(r'''
class A {
  static get f => 42;
}
main(A a) {
  a.f;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
    verify([source]);
  }

  void test_instanceAccessToStaticMember_propertyAccess_setter() {
    Source source = addSource(r'''
class A {
  static set f(x) {}
}
main(A a) {
  a.f = 42;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INSTANCE_ACCESS_TO_STATIC_MEMBER]);
    verify([source]);
  }

  void test_invalidAssignment_compoundAssignment() {
    Source source = addSource(r'''
class byte {
  int _value;
  byte(this._value);
  int operator +(int val) { return 0; }
}

void main() {
  byte b = new byte(52);
  b += 3;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_defaultValue_named() {
    Source source = addSource(r'''
f({String x: 0}) {
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_defaultValue_optional() {
    Source source = addSource(r'''
f([String x = 0]) {
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_dynamic() {
    Source source = addSource(r'''
main() {
  dynamic = 1;
}
''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_instanceVariable() {
    Source source = addSource(r'''
class A {
  int x;
}
f() {
  A a;
  a.x = '0';
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_localVariable() {
    Source source = addSource(r'''
f() {
  int x;
  x = '0';
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_regressionInIssue18468Fix() {
    // https://code.google.com/p/dart/issues/detail?id=18628
    Source source = addSource(r'''
class C<T> {
  T t = int;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_staticVariable() {
    Source source = addSource(r'''
class A {
  static int x;
}
f() {
  A.x = '0';
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_topLevelVariableDeclaration() {
    Source source = addSource("int x = 'string';");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_typeParameter() {
    // 14221
    Source source = addSource(r'''
class B<T> {
  T value;
  void test(num n) {
    value = n;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_variableDeclaration() {
    Source source = addSource(r'''
class A {
  int x = 'string';
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invocationOfNonFunction_class() {
    Source source = addSource(r'''
class A {
  void m() {
    A();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
  }

  void test_invocationOfNonFunction_localVariable() {
    Source source = addSource(r'''
f() {
  int x;
  return x();
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    verify([source]);
  }

  void test_invocationOfNonFunction_ordinaryInvocation() {
    Source source = addSource(r'''
class A {
  static int x;
}
class B {
  m() {
    A.x();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    // A call to verify(source) fails as A.x() cannot be resolved.
  }

  void test_invocationOfNonFunction_staticInvocation() {
    Source source = addSource(r'''
class A {
  static int get g => 0;
  f() {
    A.g();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    // A call to verify(source) fails as g() cannot be resolved.
  }

  void test_invocationOfNonFunction_superExpression() {
    Source source = addSource(r'''
class A {
  int get g => 0;
}
class B extends A {
  m() {
    var v = super.g();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION]);
    verify([source]);
  }

  void test_invocationOfNonFunctionExpression_literal() {
    Source source = addSource(r'''
f() {
  3(5);
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION]);
    verify([source]);
  }

  void test_nonBoolCondition_conditional() {
    Source source = addSource("f() { return 3 ? 2 : 1; }");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }

  void test_nonBoolCondition_do() {
    Source source = addSource(r'''
f() {
  do {} while (3);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }

  void test_nonBoolCondition_if() {
    Source source = addSource(r'''
f() {
  if (3) return 2; else return 1;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }

  void test_nonBoolCondition_while() {
    Source source = addSource(r'''
f() {
  while (3) {}
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_CONDITION]);
    verify([source]);
  }

  void test_nonBoolExpression_functionType() {
    Source source = addSource(r'''
int makeAssertion() => 1;
f() {
  assert(makeAssertion);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_EXPRESSION]);
    verify([source]);
  }

  void test_nonBoolExpression_interfaceType() {
    Source source = addSource(r'''
f() {
  assert(0);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_EXPRESSION]);
    verify([source]);
  }

  void test_nonBoolNegationExpression() {
    Source source = addSource(r'''
f() {
  !42;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_NEGATION_EXPRESSION]);
    verify([source]);
  }

  void test_nonBoolOperand_and_left() {
    Source source = addSource(r'''
bool f(int left, bool right) {
  return left && right;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
  }

  void test_nonBoolOperand_and_right() {
    Source source = addSource(r'''
bool f(bool left, String right) {
  return left && right;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
  }

  void test_nonBoolOperand_or_left() {
    Source source = addSource(r'''
bool f(List<int> left, bool right) {
  return left || right;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
  }

  void test_nonBoolOperand_or_right() {
    Source source = addSource(r'''
bool f(bool left, double right) {
  return left || right;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
  }

  void test_nonTypeAsTypeArgument_notAType() {
    Source source = addSource(r'''
int A;
class B<E> {}
f(B<A> b) {}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
    verify([source]);
  }

  void test_nonTypeAsTypeArgument_undefinedIdentifier() {
    Source source = addSource(r'''
class B<E> {}
f(B<A> b) {}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
    verify([source]);
  }

  void test_notEnoughRequiredArguments_mergedUnionTypeMethod() {
    enableUnionTypes(false);
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m(String x) => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m();
}''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_function() {
    Source source = addSource("int f() => '0';");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_getter() {
    Source source = addSource("int get g => '0';");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_localFunction() {
    Source source = addSource(r'''
class A {
  String m() {
    int f() => '0';
    return '0';
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_method() {
    Source source = addSource(r'''
class A {
  int f() => '0';
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_expressionFunctionBody_void() {
    Source source = addSource("void f() => 42;");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_function() {
    Source source = addSource("int f() { return '0'; }");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_getter() {
    Source source = addSource("int get g { return '0'; }");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_localFunction() {
    Source source = addSource(r'''
class A {
  String m() {
    int f() { return '0'; }
    return '0';
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_method() {
    Source source = addSource(r'''
class A {
  int f() { return '0'; }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_returnOfInvalidType_void() {
    Source source = addSource("void f() { return 42; }");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_classTypeAlias() {
    Source source = addSource(r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D = G<B> with C;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_extends() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
class C extends G<B>{}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_extends_regressionInIssue18468Fix() {
    // https://code.google.com/p/dart/issues/detail?id=18628
    Source source = addSource(r'''
class X<T extends Type> {}
class Y<U> extends X<U> {}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_fieldFormalParameter() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  var f;
  C(G<B> this.f) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_functionReturnType() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
G<B> f() { return null; }''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_functionTypeAlias() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
typedef G<B> f();''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_functionTypedFormalParameter() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> h()) {}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_implements() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
class C implements G<B>{}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_is() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
var b = 1 is G<B>;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_methodReturnType() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
class C {
  G<B> m() { return null; }
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_new() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
f() { return new G<B>(); }''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_new_superTypeOfUpperBound() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C extends B {}
class G<E extends B> {}
f() { return new G<A>(); }''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_parameter() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
f(G<B> g) {}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_redirectingConstructor() {
    Source source = addSource(r'''
class A {}
class B {}
class X<T extends A> {
  X(int x, int y) {}
  factory X.name(int x, int y) = X<B>;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS,
            StaticWarningCode.REDIRECT_TO_INVALID_RETURN_TYPE]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_typeArgumentList() {
    Source source = addSource(r'''
class A {}
class B {}
class C<E> {}
class D<E extends A> {}
C<D<B>> Var;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_typeParameter() {
    Source source = addSource(r'''
class A {}
class B {}
class C {}
class G<E extends A> {}
class D<F extends G<B>> {}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_variableDeclaration() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
G<B> g;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_with() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {}
class C extends Object with G<B>{}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_typeParameterSupertypeOfItsBound() {
    Source source = addSource(r'''
class A<T extends T> {
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.TYPE_PARAMETER_SUPERTYPE_OF_ITS_BOUND]);
    verify([source]);
  }

  void
      test_typePromotion_booleanAnd_useInRight_accessedInClosureRight_mutated() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  (p is String) && callMe(() { p.length; });
  p = 0;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_booleanAnd_useInRight_mutatedInLeft() {
    Source source = addSource(r'''
main(Object p) {
  ((p is String) && ((p = 42) == 42)) && p.length != 0;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_booleanAnd_useInRight_mutatedInRight() {
    Source source = addSource(r'''
main(Object p) {
  (p is String) && (((p = 42) == 42) && p.length != 0);
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void
      test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_after() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  p is String ? callMe(() { p.length; }) : 0;
  p = 42;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void
      test_typePromotion_conditional_useInThen_accessedInClosure_hasAssignment_before() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  p = 42;
  p is String ? callMe(() { p.length; }) : 0;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_conditional_useInThen_hasAssignment() {
    Source source = addSource(r'''
main(Object p) {
  p is String ? (p.length + (p = 42)) : 0;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_accessedInClosure_hasAssignment() {
    Source source = addSource(r'''
callMe(f()) { f(); }
main(Object p) {
  if (p is String) {
    callMe(() {
      p.length;
    });
  }
  p = 0;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_and_right_hasAssignment() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String && (p = null) == null) {
    p.length;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_extends_notMoreSpecific_dynamic() {
    Source source = addSource(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_extends_notMoreSpecific_notMoreSpecificTypeArg() {
    Source source = addSource(r'''
class V {}
class A<T> {}
class B<S> extends A<S> {
  var b;
}

main(A<V> p) {
  if (p is B<int>) {
    p.b;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_after() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
    p = 0;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_before() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p = 0;
    p.length;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_anonymous_after() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  () {p = 0;};
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_anonymous_before() {
    Source source = addSource(r'''
main(Object p) {
  () {p = 0;};
  if (p is String) {
    p.length;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_function_after() {
    Source source = addSource(r'''
main(Object p) {
  if (p is String) {
    p.length;
  }
  f() {p = 0;};
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_hasAssignment_inClosure_function_before() {
    Source source = addSource(r'''
main(Object p) {
  f() {p = 0;};
  if (p is String) {
    p.length;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_implements_notMoreSpecific_dynamic() {
    Source source = addSource(r'''
class V {}
class A<T> {}
class B<S> implements A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_typePromotion_if_with_notMoreSpecific_dynamic() {
    Source source = addSource(r'''
class V {}
class A<T> {}
class B<S> extends Object with A<S> {
  var b;
}

main(A<V> p) {
  if (p is B) {
    p.b;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedFunction() {
    Source source = addSource(r'''
void f() {
  g();
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedFunction_hasImportPrefix() {
    Source source = addSource(r'''
import 'lib.dart' as f;
main() { return f(); }''');
    addNamedSource("/lib.dart", "library lib;");
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedFunction_inCatch() {
    Source source = addSource(r'''
void f() {
  try {
  } on Object {
    g();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedFunction_inImportedLib() {
    Source source = addSource(r'''
import 'lib.dart' as f;
main() { return f.g(); }''');
    addNamedSource("/lib.dart", r'''
library lib;
h() {}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_FUNCTION]);
  }

  void test_undefinedGetter() {
    Source source = addSource(r'''
class T {}
f(T e) { return e.m; }''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_proxy_annotation_fakeProxy() {
    Source source = addSource(r'''
library L;
class Fake {
  const Fake();
}
const proxy = const Fake();
@proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_static() {
    Source source = addSource(r'''
class A {}
var a = A.B;''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_void() {
    Source source = addSource(r'''
class T {
  void m() {}
}
f(T e) { return e.m().f; }''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_wrongNumberOfTypeArguments_tooLittle() {
    Source source = addSource(r'''
class A<K, V> {
  K element;
}
main(A<int> a) {
  a.element.anyGetterExistsInDynamic;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_undefinedGetter_wrongNumberOfTypeArguments_tooMany() {
    Source source = addSource(r'''
class A<E> {
  E element;
}
main(A<int,int> a) {
  a.element.anyGetterExistsInDynamic;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_undefinedGetter_wrongOfTypeArgument() {
    Source source = addSource(r'''
class A<E> {
  E element;
}
main(A<NoSuchType> a) {
  a.element.anyGetterExistsInDynamic;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.NON_TYPE_AS_TYPE_ARGUMENT]);
    verify([source]);
  }

  void test_undefinedMethod() {
    Source source = addSource(r'''
class A {
  void m() {
    n();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_assignmentExpression() {
    Source source = addSource(r'''
class A {}
class B {
  f(A a) {
    A a2 = new A();
    a += a2;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_ignoreTypePropagation() {
    Source source = addSource(r'''
class A {}
class B extends A {
  m() {}
}
class C {
  f() {
    A a = new B();
    a.m();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_private() {
    addNamedSource("/lib.dart", r'''
library lib;
class A {
  _foo() {}
}''');
    Source source = addSource(r'''
import 'lib.dart';
class B extends A {
  test() {
    _foo();
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_proxy_annotation_fakeProxy() {
    Source source = addSource(r'''
library L;
class Fake {
  const Fake();
}
const proxy = const Fake();
@proxy class PrefixProxy {}
main() {
  new PrefixProxy().foo();
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_METHOD]);
  }

  void test_undefinedOperator_indexBoth() {
    Source source = addSource(r'''
class A {}
f(A a) {
  a[0]++;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexGetter() {
    Source source = addSource(r'''
class A {}
f(A a) {
  a[0];
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexSetter() {
    Source source = addSource(r'''
class A {}
f(A a) {
  a[0] = 1;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_plus() {
    Source source = addSource(r'''
class A {}
f(A a) {
  a + 1;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_postfixExpression() {
    Source source = addSource(r'''
class A {}
f(A a) {
  a++;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_prefixExpression() {
    Source source = addSource(r'''
class A {}
f(A a) {
  ++a;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedSetter() {
    Source source = addSource(r'''
class T {}
f(T e1) { e1.m = 0; }''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_static() {
    Source source = addSource(r'''
class A {}
f() { A.B = 0;}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_void() {
    Source source = addSource(r'''
class T {
  void m() {}
}
f(T e) { e.m().f = 0; }''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSuperMethod() {
    Source source = addSource(r'''
class A {}
class B extends A {
  m() { return super.m(); }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_SUPER_METHOD]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_getter() {
    Source source = addSource(r'''
class A {
  static int get a => 0;
}
class B extends A {
  int b() {
    return a;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER]);
    verify([source]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_method() {
    Source source = addSource(r'''
class A {
  static void a() {}
}
class B extends A {
  void b() {
    a();
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER]);
    verify([source]);
  }

  void test_unqualifiedReferenceToNonLocalStaticMember_setter() {
    Source source = addSource(r'''
class A {
  static set a(x) {}
}
class B extends A {
  b(y) {
    a = y;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.UNQUALIFIED_REFERENCE_TO_NON_LOCAL_STATIC_MEMBER]);
    verify([source]);
  }

  void test_wrongNumberOfTypeArguments_classAlias() {
    Source source = addSource(r'''
class A {}
class M {}
class B<F extends num> = A<F> with M;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_wrongNumberOfTypeArguments_tooFew() {
    Source source = addSource(r'''
class A<E, F> {}
A<A> a = null;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_wrongNumberOfTypeArguments_tooMany() {
    Source source = addSource(r'''
class A<E> {}
A<A, A> a = null;''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_wrongNumberOfTypeArguments_typeTest_tooFew() {
    Source source = addSource(r'''
class A {}
class C<K, V> {}
f(p) {
  return p is C<A>;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }

  void test_wrongNumberOfTypeArguments_typeTest_tooMany() {
    Source source = addSource(r'''
class A {}
class C<E> {}
f(p) {
  return p is C<A, A>;
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS]);
    verify([source]);
  }
}
