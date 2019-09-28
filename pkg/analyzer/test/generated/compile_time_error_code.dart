// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test/test.dart' show expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import 'test_support.dart';

class CompileTimeErrorCodeTestBase extends DriverResolutionTest {
  disabled_test_conflictingGenericInterfaces_hierarchyLoop_infinite() async {
    // There is an interface conflict here due to a loop in the class
    // hierarchy leading to an infinite set of implemented types; this loop
    // shouldn't cause non-termination.

    // TODO(paulberry): this test is currently disabled due to non-termination
    // bugs elsewhere in the analyzer.
    await assertErrorsInCode('''
class A<T> implements B<List<T>> {}
class B<T> implements A<List<T>> {}
''', [
      error(CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES, 0, 0),
    ]);
  }

  @failingTest
  test_accessPrivateEnumField() async {
    await assertErrorsInCode(r'''
enum E { ONE }
String name(E e) {
  return e._name;
}
''', [
      error(CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD, 45, 5),
    ]);
  }

  test_annotationWithNotClass() async {
    await assertErrorsInCode('''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);

@property(123)
main() {
}
''', [
      error(CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS, 117, 8),
    ]);
  }

  test_annotationWithNotClass_prefixed() async {
    newFile("/test/lib/annotations.dart", content: r'''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);
''');
    await assertErrorsInCode('''
import 'annotations.dart' as pref;
@pref.property(123)
main() {
}
''', [
      error(CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS, 36, 13),
    ]);
  }

  test_asyncForInWrongContext() async {
    await assertErrorsInCode(r'''
f(list) {
  await for (var e in list) {
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 27, 1),
      error(CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT, 29, 2),
    ]);
  }

  test_awaitInWrongContext_sync() async {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    await assertErrorsInCode(r'''
f(x) {
  return await x;
}
''', [
      error(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 16, 5),
    ]);
  }

  test_awaitInWrongContext_syncStar() async {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    await assertErrorsInCode(r'''
f(x) sync* {
  yield await x;
}
''', [
      error(CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT, 21, 5),
    ]);
  }

  test_bug_23176() async {
    await assertErrorsInCode('''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 40, 7),
      error(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 40, 7),
      error(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 62, 1),
    ]);
  }

  test_builtInIdentifierAsMixinName_classTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class as = A with B;
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 28, 2),
    ]);
  }

  test_builtInIdentifierAsPrefixName() async {
    await assertErrorsInCode('''
import 'dart:async' as abstract;
''', [
      error(HintCode.UNUSED_IMPORT, 7, 12),
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME, 23, 8),
    ]);
  }

  test_builtInIdentifierAsType_dynamicMissingPrefix() async {
    await assertErrorsInCode('''
import 'dart:core' as core;

dynamic x;
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE, 29, 7),
    ]);
  }

  test_builtInIdentifierAsType_formalParameter_field() async {
    await assertErrorsInCode(r'''
class A {
  var x;
  A(static this.x);
}
''', [
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 23, 6),
    ]);
  }

  test_builtInIdentifierAsType_formalParameter_simple() async {
    await assertErrorsInCode(r'''
f(static x) {
}
''', [
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 2, 6),
    ]);
  }

  test_builtInIdentifierAsType_variableDeclaration() async {
    await assertErrorsInCode(r'''
f() {
  typedef x;
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 8, 7),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 8, 7),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 16, 1),
    ]);
  }

  test_builtInIdentifierAsTypedefName_functionTypeAlias() async {
    await assertErrorsInCode('''
typedef bool as();
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME, 13, 2),
    ]);
  }

  test_builtInIdentifierAsTypeName() async {
    await assertErrorsInCode('''
class as {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME, 6, 2),
    ]);
  }

  test_builtInIdentifierAsTypeParameterName() async {
    await assertErrorsInCode('''
class A<as> {}
''', [
      error(CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME, 8,
          2),
    ]);
  }

  test_caseExpressionTypeImplementsEquals() async {
    await assertErrorsInCode(r'''
class IntWrapper {
  final int value;
  const IntWrapper(this.value);
  bool operator ==(Object x) {
    return x is IntWrapper && x.value == value;
  }
  get hashCode => value;
}

f(var a) {
  switch(a) {
    case(const IntWrapper(1)) : return 1;
    default: return 0;
  }
}
''', [
      error(
          CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, 194, 6),
    ]);
  }

  test_conflictingGenericInterfaces_hierarchyLoop() async {
    // There is no interface conflict here, but there is a loop in the class
    // hierarchy leading to a finite set of implemented types; this loop
    // shouldn't cause non-termination.
    await assertErrorsInCode('''
class A<T> implements B<T> {}
class B<T> implements A<T> {}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 36, 1),
    ]);
  }

  test_conflictingGenericInterfaces_noConflict() async {
    await assertNoErrorsInCode('''
class I<T> {}
class A implements I<int> {}
class B implements I<int> {}
class C extends A implements B {}
''');
  }

  test_conflictingTypeVariableAndClass() async {
    await assertErrorsInCode(r'''
class T<T> {
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS, 8, 1),
    ]);
  }

  test_conflictingTypeVariableAndMember_field() async {
    await assertErrorsInCode(r'''
class A<T> {
  var T;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, 8, 1),
    ]);
  }

  test_conflictingTypeVariableAndMember_getter() async {
    await assertErrorsInCode(r'''
class A<T> {
  get T => null;
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, 8, 1),
    ]);
  }

  test_conflictingTypeVariableAndMember_method() async {
    await assertErrorsInCode(r'''
class A<T> {
  T() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, 8, 1),
    ]);
  }

  test_conflictingTypeVariableAndMember_method_static() async {
    await assertErrorsInCode(r'''
class A<T> {
  static T() {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, 8, 1),
    ]);
  }

  test_conflictingTypeVariableAndMember_setter() async {
    await assertErrorsInCode(r'''
class A<T> {
  set T(x) {}
}
''', [
      error(CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER, 8, 1),
    ]);
  }

  test_consistentCaseExpressionTypes_dynamic() async {
    // Even though A.S and S have a static type of "dynamic", we should see
    // that they match 'abc', because they are constant strings.
    await assertNoErrorsInCode(r'''
class A {
  static const S = 'A.S';
}

const S = 'S';

foo(var p) {
  switch (p) {
    case S:
      break;
    case A.S:
      break;
    case 'abc':
      break;
  }
}
''');
  }

  test_const_invalid_constructorFieldInitializer_fromLibrary() async {
    newFile('/test/lib/lib.dart', content: r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
const a = const A();
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 29, 9),
    ]);
  }

  test_constConstructor_redirect_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  const A(T value) : this._(value);
  const A._(T value) : value = value;
  final T value;
}

void main(){
  const A<int>(1);
}
''');
  }

  test_constConstructorWithFieldInitializedByNonConst() async {
    await assertErrorsInCode(r'''
class A {
  final int i = f();
  const A();
}
int f() {
  return 3;
}
''', [
      error(
          CompileTimeErrorCode
              .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
          33,
          10),
    ]);
  }

  test_constConstructorWithFieldInitializedByNonConst_static() async {
    await assertNoErrorsInCode(r'''
class A {
  static final int i = f();
  const A();
}
int f() {
  return 3;
}
''');
  }

  test_constConstructorWithNonConstSuper_explicit() async {
    await assertErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  const B(): super();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, 52, 7),
    ]);
  }

  test_constConstructorWithNonConstSuper_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  const B();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, 47, 1),
    ]);
  }

  test_constConstructorWithNonFinalField_mixin() async {
    await assertErrorsInCode(r'''
class A {
  var a;
}
class B extends Object with A {
  const B();
}
''', [
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 55, 10),
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD, 61, 1),
    ]);
  }

  test_constConstructorWithNonFinalField_super() async {
    await assertErrorsInCode(r'''
class A {
  var a;
}
class B extends A {
  const B();
}
''', [
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 43, 10),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, 49, 1),
    ]);
  }

  test_constConstructorWithNonFinalField_this() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  const A();
}
''', [
      error(
          CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 21, 10),
    ]);
  }

  test_constDeferredClass() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {
  const A();
}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A();
}
''', [
      error(CompileTimeErrorCode.CONST_DEFERRED_CLASS, 65, 3),
    ]);
  }

  test_constDeferredClass_namedConstructor() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {
  const A.b();
}''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A.b();
}''', [
      error(CompileTimeErrorCode.CONST_DEFERRED_CLASS, 65, 5),
    ]);
  }

  test_constEval_newInstance_constConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
const a = new A();
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 35,
          7),
    ]);
  }

  test_constEval_newInstance_externalFactoryConstConstructor() async {
    // We can't evaluate "const A()" because its constructor is external.  But
    // the code is correct--we shouldn't report an error.
    await assertNoErrorsInCode(r'''
class A {
  external const factory A();
}
const x = const A();
''');
  }

  test_constEval_nonStaticField_inGenericClass() async {
    await assertErrorsInCode('''
class C<T> {
  const C();
  T get t => null;
}

const x = const C().t;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 58,
          11),
    ]);
  }

  test_constEval_propertyExtraction_targetNotConst() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  int m() => 0;
}
final a = const A();
const C = a.m;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 72,
          1),
    ]);
  }

  test_constEvalThrowsException() async {
    await assertErrorsInCode(r'''
class C {
  const C();
}
f() { return const C(); }
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION, 0, 0),
    ]);
  }

  test_constEvalThrowsException_binaryMinus_null() async {
    await _check_constEvalThrowsException_binary_null('null - 5', false);
    await _check_constEvalThrowsException_binary_null('5 - null', true);
  }

  test_constEvalThrowsException_binaryPlus_null() async {
    await _check_constEvalThrowsException_binary_null('null + 5', false);
    await _check_constEvalThrowsException_binary_null('5 + null', true);
  }

  test_constEvalThrowsException_divisionByZero() async {
    await assertErrorsInCode('''
const C = 1 ~/ 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE, 10, 6),
    ]);
  }

  test_constEvalThrowsException_finalAlreadySet_initializer() async {
    // If a final variable has an initializer at the site of its declaration,
    // and at the site of the constructor, then invoking that constructor would
    // produce a runtime error; hence invoking that constructor via the "const"
    // keyword results in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C() : x = 2;
}
var x = const C();
''', [
      error(StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION,
          39, 1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 56, 9),
    ]);
  }

  test_constEvalThrowsException_finalAlreadySet_initializing_formal() async {
    // If a final variable has an initializer at the site of its declaration,
    // and it is initialized using an initializing formal at the site of the
    // constructor, then invoking that constructor would produce a runtime
    // error; hence invoking that constructor via the "const" keyword results
    // in a compile-time error.
    await assertErrorsInCode('''
class C {
  final x = 1;
  const C(this.x);
}
var x = const C(2);
''', [
      error(StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR,
          40, 1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 54, 10),
    ]);
  }

  test_constEvalThrowsException_unaryBitNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = ~D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_constEvalThrowsException_unaryNegated_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = -D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_constEvalThrowsException_unaryNot_null() async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = !D;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 2),
    ]);
  }

  test_constEvalTypeBool_binary_and() async {
    await assertErrorsInCode('''
const _ = true && '';
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 10),
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 18, 2),
    ]);
  }

  test_constEvalTypeBool_binary_leftTrue() async {
    await assertErrorsInCode('''
const C = (true || 0);
''', [
      error(HintCode.DEAD_CODE, 19, 1),
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 19, 1),
    ]);
  }

  test_constEvalTypeBool_binary_or() async {
    await assertErrorsInCode(r'''
const _ = false || '';
''', [
      error(HintCode.UNUSED_ELEMENT, 6, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 10, 11),
      error(StaticTypeWarningCode.NON_BOOL_OPERAND, 19, 2),
    ]);
  }

  test_constEvalTypeBool_logicalOr_trueLeftOperand() async {
    await assertNoErrorsInCode(r'''
class C {
  final int x;
  const C({this.x}) : assert(x == null || x >= 0);
}
const c = const C();
''');
  }

  test_constEvalTypeBoolNumString_equal() async {
    await assertErrorsInCode(
        r'''
class A {
  const A();
}

const num a = 0;
const b = a == const A();
''',
        IsEnabledByDefault.constant_update_2018
            ? []
            : [
                error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 53,
                    14),
              ]);
  }

  test_constEvalTypeBoolNumString_notEqual() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

const num a = 0;
const _ = a != const A();
''', [
      error(HintCode.UNUSED_ELEMENT, 49, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING, 53, 14),
    ]);
  }

  test_constEvalTypeInt_binary() async {
    await _check_constEvalTypeBoolOrInt_binary("a ^ ''");
    await _check_constEvalTypeBoolOrInt_binary("a & ''");
    await _check_constEvalTypeBoolOrInt_binary("a | ''");
    await _check_constEvalTypeInt_binary("a >> ''");
    await _check_constEvalTypeInt_binary("a << ''");
  }

  test_constEvalTypeNum_binary() async {
    await _check_constEvalTypeNum_binary("a + ''");
    await _check_constEvalTypeNum_binary("a - ''");
    await _check_constEvalTypeNum_binary("a * ''");
    await _check_constEvalTypeNum_binary("a / ''");
    await _check_constEvalTypeNum_binary("a ~/ ''");
    await _check_constEvalTypeNum_binary("a > ''");
    await _check_constEvalTypeNum_binary("a < ''");
    await _check_constEvalTypeNum_binary("a >= ''");
    await _check_constEvalTypeNum_binary("a <= ''");
    await _check_constEvalTypeNum_binary("a % ''");
  }

  test_constFormalParameter_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  var x;
  A(const this.x) {}
}
''', [
      error(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, 23, 12),
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 23, 5),
    ]);
  }

  test_constFormalParameter_simpleFormalParameter() async {
    await assertErrorsInCode('''
f(const x) {}
''', [
      error(CompileTimeErrorCode.CONST_FORMAL_PARAMETER, 2, 7),
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 2, 5),
    ]);
  }

  test_constInitializedWithNonConstValue() async {
    await assertErrorsInCode(r'''
f(p) {
  const C = p;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 15, 1),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 19,
          1),
    ]);
  }

  test_constInitializedWithNonConstValue_finalField() async {
    // Regression test for bug #25526 which previously
    // caused two errors to be reported.
    await assertErrorsInCode(r'''
class Foo {
  final field = 0;
  foo([int x = field]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 46, 5),
    ]);
  }

  test_constInitializedWithNonConstValue_missingConstInListLiteral() async {
    await assertNoErrorsInCode('''
const List L = [0];
''');
  }

  test_constInitializedWithNonConstValue_missingConstInMapLiteral() async {
    await assertNoErrorsInCode('''
const Map M = {'a' : 0};
''');
  }

  test_constInitializedWithNonConstValueFromDeferredClass() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
const B = a.V;
''', [
      error(
          CompileTimeErrorCode
              .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY,
          58,
          3),
    ]);
  }

  test_constInitializedWithNonConstValueFromDeferredClass_nested() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
const B = a.V + 1;
''', [
      error(
          CompileTimeErrorCode
              .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY,
          58,
          7),
    ]);
  }

  test_constInstanceField() async {
    await assertErrorsInCode(r'''
class C {
  const int f = 0;
}
''', [
      error(CompileTimeErrorCode.CONST_INSTANCE_FIELD, 12, 5),
    ]);
  }

  test_constWithInvalidTypeParameters() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
f() { return const A<A>(); }
''', [
      error(CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS, 44, 4),
    ]);
  }

  test_constWithInvalidTypeParameters_tooFew() async {
    await assertErrorsInCode(r'''
class A {}
class C<K, V> {
  const C();
}
f(p) {
  return const C<A>();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS, 64, 4),
    ]);
  }

  test_constWithInvalidTypeParameters_tooMany() async {
    await assertErrorsInCode(r'''
class A {}
class C<E> {
  const C();
}
f(p) {
  return const C<A, A>();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS, 61, 7),
    ]);
  }

  test_constWithNonConst() async {
    await assertErrorsInCode(r'''
class T {
  T(a, b, {c, d}) {}
}
f() { return const T(0, 1, c: 2, d: 3); }
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 46, 25),
    ]);
  }

  test_constWithNonConst_in_const_context() async {
    await assertErrorsInCode(r'''
class A {
  const A(x);
}
class B {
}
main() {
  const A(B());
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 57, 3),
    ]);
  }

  test_constWithNonConstantArgument_annotation() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
var v = 42;
@A(v)
main() {
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, 45, 1),
    ]);
  }

  test_constWithNonConstantArgument_instanceCreation() async {
    await assertErrorsInCode(r'''
class A {
  const A(a);
}
f(p) { return const A(p); }
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT, 48, 1),
    ]);
  }

  test_constWithNonType() async {
    await assertErrorsInCode(r'''
int A;
f() {
  return const A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_TYPE, 28, 1),
    ]);
  }

  test_constWithNonType_fromLibrary() async {
    newFile('/test/lib/lib1.dart');
    await assertErrorsInCode('''
import 'lib1.dart' as lib;
void f() {
  const lib.A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_TYPE, 50, 1),
    ]);
  }

  test_constWithTypeParameters_direct() async {
    await assertErrorsInCode(r'''
class A<T> {
  static const V = const A<T>();
  const A();
}
''', [
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 40, 1),
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 40, 1),
    ]);
  }

  test_constWithTypeParameters_indirect() async {
    await assertErrorsInCode(r'''
class A<T> {
  static const V = const A<List<T>>();
  const A();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS, 45, 1),
      error(StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC, 45, 1),
    ]);
  }

  test_constWithUndefinedConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
f() {
  return const A.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR, 48, 17),
    ]);
  }

  test_constWithUndefinedConstructorDefault() async {
    await assertErrorsInCode(r'''
class A {
  const A.name();
}
f() {
  return const A();
}
''', [
      error(
          CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT, 51, 1),
    ]);
  }

  test_defaultValueInFunctionTypeAlias_new_named() async {
    await assertErrorsInCode('''
typedef F = int Function({Map<String, String> m: const {}});
''', [
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 47, 1),
    ]);
  }

  test_defaultValueInFunctionTypeAlias_new_positional() async {
    await assertErrorsInCode('''
typedef F = int Function([Map<String, String> m = const {}]);
''', [
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 48, 1),
    ]);
  }

  test_defaultValueInFunctionTypeAlias_old_named() async {
    await assertErrorsInCode('''
typedef F([x = 0]);
''', [
      error(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, 0, 19),
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 13, 1),
    ]);
  }

  test_defaultValueInFunctionTypeAlias_old_positional() async {
    await assertErrorsInCode('''
typedef F([x = 0]);
''', [
      error(CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS, 0, 19),
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 13, 1),
    ]);
  }

  test_defaultValueInFunctionTypedParameter_named() async {
    await assertErrorsInCode('''
f(g({p: null})) {}
''', [
      error(
          CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, 5, 7),
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 6, 1),
    ]);
  }

  test_defaultValueInFunctionTypedParameter_optional() async {
    await assertErrorsInCode('''
f(g([p = null])) {}
''', [
      error(
          CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER, 5, 8),
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 7, 1),
    ]);
  }

  test_defaultValueInRedirectingFactoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  factory A([int x = 0]) = B;
}

class B implements A {
  B([int x = 1]) {}
}
''', [
      error(
          CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR,
          27,
          1),
    ]);
  }

  test_deferredImportWithInvalidUri() async {
    await assertErrorsInCode(r'''
import '[invalid uri]' deferred as p;
main() {
  p.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 15),
    ]);
  }

  test_duplicateNamedArgument() async {
    await assertErrorsInCode(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, 32, 1),
    ]);
  }

  test_duplicatePart_sameSource() async {
    newFile('/test/lib/part.dart', content: 'part of lib;');
    await assertErrorsInCode(r'''
library lib;
part 'part.dart';
part 'foo/../part.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_PART, 36, 18),
    ]);
  }

  test_duplicatePart_sameUri() async {
    newFile('/test/lib/part.dart', content: 'part of lib;');
    await assertErrorsInCode(r'''
library lib;
part 'part.dart';
part 'part.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_PART, 36, 11),
    ]);
  }

  test_exportInternalLibrary() async {
    await assertErrorsInCode('''
export 'dart:_interceptors';
''', [
      error(CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY, 0, 28),
    ]);
  }

  test_exportOfNonLibrary() async {
    newFile("/test/lib/lib1.dart", content: '''
part of lib;
''');
    await assertErrorsInCode(r'''
library L;
export 'lib1.dart';
''', [
      error(CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY, 18, 11),
    ]);
  }

  test_extendsDeferredClass() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B extends a.A {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, 64, 3),
    ]);
  }

  test_extendsDeferredClass_classTypeAlias() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class M {}
class C = a.A with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS, 69, 3),
    ]);
  }

  test_extendsDisallowedClass_class_bool() async {
    await assertErrorsInCode('''
class A extends bool {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 6, 1),
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 4),
    ]);
  }

  test_extendsDisallowedClass_class_double() async {
    await assertErrorsInCode('''
class A extends double {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 6),
    ]);
  }

  test_extendsDisallowedClass_class_int() async {
    await assertErrorsInCode('''
class A extends int {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 6, 1),
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 3),
    ]);
  }

  test_extendsDisallowedClass_class_Null() async {
    await assertErrorsInCode('''
class A extends Null {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 6, 1),
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 4),
    ]);
  }

  test_extendsDisallowedClass_class_num() async {
    await assertErrorsInCode('''
class A extends num {}
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 3),
    ]);
  }

  test_extendsDisallowedClass_class_String() async {
    await assertErrorsInCode('''
class A extends String {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 6, 1),
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 16, 6),
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class M {}
class C = bool with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 4),
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class M {}
class C = double with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 6),
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class M {}
class C = int with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 3),
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class M {}
class C = Null with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 4),
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class M {}
class C = num with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 3),
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class M {}
class C = String with M;
''', [
      error(CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS, 21, 6),
    ]);
  }

  test_extraPositionalArguments_const() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
main() {
  const A(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 43, 3),
    ]);
  }

  test_extraPositionalArguments_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 64, 3),
    ]);
  }

  test_extraPositionalArgumentsCouldBeNamed_const() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x});
}
main() {
  const A(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 50,
          3),
    ]);
  }

  test_extraPositionalArgumentsCouldBeNamed_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x});
}
class B extends A {
  const B() : super(0);
}
''', [
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED, 71,
          3),
    ]);
  }

  test_fieldFormalParameter_assignedInInitializer() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x) : x = 3 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          33, 1),
    ]);
  }

  test_fieldInitializedByMultipleInitializers() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, 34,
          1),
    ]);
  }

  test_fieldInitializedByMultipleInitializers_multipleInits() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1, x = 2 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, 34,
          1),
      error(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, 41,
          1),
    ]);
  }

  test_fieldInitializedByMultipleInitializers_multipleNames() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  int y;
  A() : x = 0, x = 1, y = 0, y = 1 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, 43,
          1),
      error(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, 57,
          1),
    ]);
  }

  test_fieldInitializedInParameterAndInitializer() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x) : x = 1 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          33, 1),
    ]);
  }

  test_fieldInitializerFactoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  factory A(this.x) => null;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR, 31, 6),
    ]);
  }

  test_fieldInitializerOutsideConstructor() async {
    // TODO(brianwilkerson) Fix the duplicate error messages.
    await assertErrorsInCode(r'''
class A {
  int x;
  m(this.x) {}
}
''', [
      error(ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 23, 4),
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 23, 6),
    ]);
  }

  test_fieldInitializerOutsideConstructor_defaultParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  m([this.x]) {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 24, 6),
    ]);
  }

  test_fieldInitializerOutsideConstructor_inFunctionTypeParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(int p(this.x));
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 29, 6),
    ]);
  }

  test_fieldInitializerRedirectingConstructor_afterRedirection() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A.named() {}
  A() : this.named(), x = 42;
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 56,
          6),
    ]);
  }

  test_fieldInitializerRedirectingConstructor_beforeRedirection() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A.named() {}
  A() : x = 42, this.named();
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 42,
          6),
    ]);
  }

  test_fieldInitializingFormalRedirectingConstructor() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A.named() {}
  A(this.x) : this.named();
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR, 38,
          6),
    ]);
  }

  test_finalInitializedMultipleTimes_initializers() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A() : x = 0, x = 0 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS, 36,
          1),
    ]);
  }

  /**
   * This test doesn't test the FINAL_INITIALIZED_MULTIPLE_TIMES code, but tests the
   * FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   *
   * Note: FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER covers a subset of
   * FINAL_INITIALIZED_MULTIPLE_TIMES, since it more specific, we use it instead of the broader code
   */
  test_finalInitializedMultipleTimes_initializingFormal_initializer() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A(this.x) : x = 0 {}
}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER,
          35, 1),
    ]);
  }

  test_finalInitializedMultipleTimes_initializingFormals() async {
    // TODO(brianwilkerson) There should only be one error here.
    await assertErrorsInCode(r'''
class A {
  final x;
  A(this.x, this.x) {}
}
''', [
      error(CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES, 38, 1),
      error(CompileTimeErrorCode.DUPLICATE_DEFINITION, 38, 1),
    ]);
  }

  test_finalNotInitialized_instanceField_const_static() async {
    await assertErrorsInCode(r'''
class A {
  static const F;
}
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 25, 1),
    ]);
  }

  test_finalNotInitialized_library_const() async {
    await assertErrorsInCode('''
const F;
''', [
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 6, 1),
    ]);
  }

  test_finalNotInitialized_local_const() async {
    await assertErrorsInCode(r'''
f() {
  const int x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(CompileTimeErrorCode.CONST_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_forInWithConstVariable_forEach_identifier() async {
    await assertErrorsInCode(r'''
f() {
  const x = 0;
  for (x in [0, 1, 2]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 14, 1),
      error(StaticWarningCode.ASSIGNMENT_TO_CONST, 28, 1),
    ]);
  }

  test_forInWithConstVariable_forEach_loopVariable() async {
    await assertErrorsInCode(r'''
f() {
  for (const x in [0, 1, 2]) {}
}
''', [
      error(CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE, 13, 7),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
  }

  test_fromEnvironment_bool_badArgs() async {
    await assertErrorsInCode(r'''
var b1 = const bool.fromEnvironment(1);
var b2 = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 9, 29),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 36, 1),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 49, 48),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 81, 15),
    ]);
  }

  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    driver.declaredVariables = new DeclaredVariables.fromMap({'x': 'true'});
    await assertErrorsInCode('''
var b = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 8, 48),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 40, 15),
    ]);
  }

  test_genericFunctionTypeArgument_inference_function() async {
    await assertErrorsInCode(r'''
T f<T>(T t) => null;
main() { f(<S>(S s) => s); }
''', [
      error(StrongModeCode.COULD_NOT_INFER, 30, 1),
    ]);
  }

  test_genericFunctionTypeArgument_inference_functionType() async {
    await assertErrorsInCode(r'''
T Function<T>(T) f;
main() { f(<S>(S s) => s); }
''', [
      error(StrongModeCode.COULD_NOT_INFER, 29, 1),
    ]);
  }

  test_genericFunctionTypeArgument_inference_method() async {
    await assertErrorsInCode(r'''
class C {
  T f<T>(T t) => null;
}
main() { new C().f(<S>(S s) => s); }
''', [
      error(StrongModeCode.COULD_NOT_INFER, 52, 1),
    ]);
  }

  test_genericFunctionTypeAsBound_class() async {
    await assertErrorsInCode(r'''
class C<T extends S Function<S>(S)> {
}
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 18, 16),
    ]);
  }

  test_genericFunctionTypeAsBound_genericFunction() async {
    await assertErrorsInCode(r'''
T Function<T extends S Function<S>(S)>(T) fun;
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 21, 16),
    ]);
  }

  test_genericFunctionTypeAsBound_genericFunctionTypedef() async {
    await assertErrorsInCode(r'''
typedef foo = T Function<T extends S Function<S>(S)>(T t);
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 35, 16),
    ]);
  }

  test_genericFunctionTypeAsBound_parameterOfFunction() async {
    await assertNoErrorsInCode(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_genericFunctionTypeAsBound_typedef() async {
    await assertErrorsInCode(r'''
typedef T foo<T extends S Function<S>(S)>(T t);
''', [
      error(CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND, 24, 16),
    ]);
  }

  test_genericFunctionTypedParameter() async {
    var code = '''
void g(T f<T>(T x)) {}
''';
    await assertNoErrorsInCode(code);
  }

  test_implementsDeferredClass() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B implements a.A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, 67, 3),
    ]);
  }

  test_implementsDeferredClass_classTypeAlias() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B {}
class M {}
class C = B with M implements a.A;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS, 100, 3),
    ]);
  }

  test_implementsDisallowedClass_class_bool() async {
    await assertErrorsInCode('''
class A implements bool {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 4),
    ]);
  }

  test_implementsDisallowedClass_class_double() async {
    await assertErrorsInCode('''
class A implements double {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
    ]);
  }

  test_implementsDisallowedClass_class_int() async {
    await assertErrorsInCode('''
class A implements int {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 3),
    ]);
  }

  test_implementsDisallowedClass_class_Null() async {
    await assertErrorsInCode('''
class A implements Null {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 4),
    ]);
  }

  test_implementsDisallowedClass_class_num() async {
    await assertErrorsInCode('''
class A implements num {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 3),
    ]);
  }

  test_implementsDisallowedClass_class_String() async {
    await assertErrorsInCode('''
class A implements String {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
    ]);
  }

  test_implementsDisallowedClass_class_String_num() async {
    await assertErrorsInCode('''
class A implements String, num {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 19, 6),
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 27, 3),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements bool;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 4),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements double;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 6),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements int;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 3),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements Null;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 4),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements num;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 3),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements String;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 6),
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_String_num() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements String, num;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 52, 6),
      error(CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS, 60, 3),
    ]);
  }

  test_implementsNonClass_class() async {
    await assertErrorsInCode(r'''
int A;
class B implements A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 26, 1),
    ]);
  }

  test_implementsNonClass_dynamic() async {
    await assertErrorsInCode('''
class A implements dynamic {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 19, 7),
    ]);
  }

  test_implementsNonClass_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A implements E {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 34, 1),
    ]);
  }

  test_implementsNonClass_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
int B;
class C = A with M implements B;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_NON_CLASS, 59, 1),
    ]);
  }

  test_implementsSuperClass() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A implements A {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 40, 1),
    ]);
  }

  test_implementsSuperClass_Object() async {
    await assertErrorsInCode('''
class A implements Object {}
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 19, 6),
    ]);
  }

  test_implementsSuperClass_Object_typeAlias() async {
    await assertErrorsInCode(r'''
class M {}
class A = Object with M implements Object;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 46, 6),
    ]);
  }

  test_implementsSuperClass_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B = A with M implements A;
''', [
      error(CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS, 52, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_field() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
  var f;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 31, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_field2() async {
    await assertErrorsInCode(r'''
class A {
  final x = 0;
  final y = x;
}
''', [
      error(StrongModeCode.TOP_LEVEL_INSTANCE_GETTER, 37, 1),
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 37, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_invocation() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  A() : v = f();
  f() {}
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 31, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_invocationInStatic() async {
    await assertErrorsInCode(r'''
class A {
  static var F = m();
  int m() => 0;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 27, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    await assertErrorsInCode(r'''
class A {
  A(p) {}
  A.named() : this(f);
  var f;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 39, 1),
    ]);
  }

  test_implicitThisReferenceInInitializer_superConstructorInvocation() async {
    await assertErrorsInCode(r'''
class A {
  A(p) {}
}
class B extends A {
  B() : super(f);
  var f;
}
''', [
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 56, 1),
    ]);
  }

  test_importInternalLibrary() async {
    // Note, in these error cases we may generate an UNUSED_IMPORT hint, while
    // we could prevent the hint from being generated by testing the import
    // directive for the error, this is such a minor corner case that we don't
    // think we should add the additional computation time to figure out such
    // cases.
    await assertErrorsInCode('''
import 'dart:_interceptors';
''', [
      error(CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, 7, 20),
      error(HintCode.UNUSED_IMPORT, 7, 20),
    ]);
  }

  test_importOfNonLibrary() async {
    newFile("/test/lib/part.dart", content: r'''
part of lib;
class A{}
''');
    await assertErrorsInCode(r'''
library lib;
import 'part.dart';
A a;
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY, 20, 11),
    ]);
  }

  test_inconsistentCaseExpressionTypes() async {
    await assertErrorsInCode(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 'a':
      break;
  }
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 60, 3),
    ]);
  }

  test_inconsistentCaseExpressionTypes_dynamic() async {
    // Even though A.S and S have a static type of "dynamic", we should see
    // that they fail to match 3, because they are constant strings.
    await assertErrorsInCode(r'''
class A {
  static const S = 'A.S';
}

const S = 'S';

foo(var p) {
  switch (p) {
    case 3:
      break;
    case S:
      break;
    case A.S:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 117, 1),
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 142, 3),
    ]);
  }

  test_inconsistentCaseExpressionTypes_repeated() async {
    await assertErrorsInCode(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 'a':
      break;
    case 'b':
      break;
  }
}
''', [
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 60, 3),
      error(CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES, 87, 3),
    ]);
  }

  test_initializerForNonExistent_const() async {
    // Check that the absence of a matching field doesn't cause a
    // crash during constant evaluation.
    await assertErrorsInCode(r'''
class A {
  const A() : x = 'foo';
}
A a = const A();
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 24, 9),
    ]);
  }

  test_initializerForNonExistent_initializer() async {
    await assertErrorsInCode(r'''
class A {
  A() : x = 0 {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD, 18, 5),
    ]);
  }

  test_initializerForStaticField() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
  A() : x = 0 {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD, 34, 5),
    ]);
  }

  test_initializingFormalForNonExistentField() async {
    await assertErrorsInCode(r'''
class A {
  A(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 14,
          6),
    ]);
  }

  test_initializingFormalForNonExistentField_notInEnclosingClass() async {
    await assertErrorsInCode(r'''
class A {
int x;
}
class B extends A {
  B(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 43,
          6),
    ]);
  }

  test_initializingFormalForNonExistentField_optional() async {
    await assertErrorsInCode(r'''
class A {
  A([this.x]) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 15,
          6),
    ]);
  }

  test_initializingFormalForNonExistentField_synthetic() async {
    await assertErrorsInCode(r'''
class A {
  int get x => 1;
  A(this.x) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD, 32,
          6),
    ]);
  }

  test_initializingFormalForStaticField() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
  A([this.x]) {}
}
''', [
      error(CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD, 31, 6),
    ]);
  }

  test_instanceMemberAccessFromFactory_named() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
  A();
  factory A.make() {
    m();
    return new A();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 51, 1),
    ]);
  }

  test_instanceMemberAccessFromFactory_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
  A._();
  factory A() {
    m();
    return new A._();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY, 48, 1),
    ]);
  }

  test_instanceMemberAccessFromStatic_field() async {
    await assertErrorsInCode(r'''
class A {
  int f;
  static foo() {
    f;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 40, 1),
    ]);
  }

  test_instanceMemberAccessFromStatic_getter() async {
    await assertErrorsInCode(r'''
class A {
  get g => null;
  static foo() {
    g;
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 48, 1),
    ]);
  }

  test_instanceMemberAccessFromStatic_method() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
  static foo() {
    m();
  }
}
''', [
      error(CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC, 40, 1),
    ]);
  }

  test_instantiate_to_bounds_not_matching_bounds() async {
    // There should be an error, because Bar's type argument T is Foo, which
    // doesn't extends Foo<T>.
    await assertErrorsInCode('''
class Foo<T> {}
class Bar<T extends Foo<T>> {}
class Baz extends Bar {}
void main() {}
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 65, 3),
    ]);
    // Instantiate-to-bounds should have instantiated "Bar" to "Bar<Foo>".
    expect(result.unit.declaredElement.getType('Baz').supertype.toString(),
        'Bar<Foo<dynamic>>');
  }

  test_instantiateEnum_const() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e(String name) {
  return const E();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ENUM, 49, 1),
    ]);
  }

  test_instantiateEnum_new() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e(String name) {
  return new E();
}
''', [
      error(CompileTimeErrorCode.INSTANTIATE_ENUM, 47, 1),
    ]);
  }

  test_integerLiteralAsDoubleOutOfRange_excessiveExponent() async {
    await assertErrorsInCode(
        'double x = 0xfffffffffffff80000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000000000'
        '000000000000000000000000000000000000000000000000000000000000;',
        [
          error(CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE, 11,
              259),
        ]);
    AnalysisError firstError = result.errors[0];

    // Check that we suggest the max double instead.
    expect(
        true,
        firstError.correction.contains(
            '179769313486231570814527423731704356798070567525844996598917476803'
            '157260780028538760589558632766878171540458953514382464234321326889'
            '464182768467546703537516986049910576551282076245490090389328944075'
            '868508455133942304583236903222948165808559332123348274797826204144'
            '723168738177180919299881250404026184124858368'));
  }

  test_integerLiteralAsDoubleOutOfRange_excessiveMantissa() async {
    await assertErrorsInCode('''
double x = 9223372036854775809;
''', [
      error(CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE, 11, 19),
    ]);
    AnalysisError firstError = result.errors[0];
    // Check that we suggest a valid double instead.
    expect(true, firstError.correction.contains('9223372036854775808'));
  }

  test_integerLiteralOutOfRange_negative() async {
    await assertErrorsInCode('''
int x = -9223372036854775809;
''', [
      error(CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE, 9, 19),
    ]);
  }

  test_integerLiteralOutOfRange_positive() async {
    await assertErrorsInCode('''
int x = 9223372036854775808;
''', [
      error(CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE, 8, 19),
    ]);
  }

  test_invalidAnnotation_importWithPrefix_notConstantVariable() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
final V = 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
typedef V();
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 24, 4),
    ]);
  }

  test_invalidAnnotation_notConstantVariable() async {
    await assertErrorsInCode(r'''
final V = 0;
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 13, 2),
    ]);
  }

  test_invalidAnnotation_notVariableOrConstructorInvocation() async {
    await assertErrorsInCode(r'''
typedef V();
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 13, 2),
    ]);
  }

  test_invalidAnnotation_staticMethodReference() async {
    await assertErrorsInCode(r'''
class A {
  static f() {}
}
@A.f
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION, 28, 4),
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary() async {
    // See test_invalidAnnotation_notConstantVariable
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class V { const V(); }
const v = const V();
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
@a.v main () {}
''', [
      error(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary_constructor() async {
    // See test_invalidAnnotation_notConstantVariable
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class C { const C(); }
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
@a.C() main () {}
''', [
      error(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    // See test_invalidAnnotation_notConstantVariable
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class C { const C.name(); }
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
@a.C.name() main () {}
''', [
      error(
          CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY, 49, 3),
    ]);
  }

  test_invalidAnnotationGetter_getter() async {
    await assertErrorsInCode(r'''
get V => 0;
@V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, 12, 2),
    ]);
  }

  test_invalidAnnotationGetter_importWithPrefix_getter() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
get V => 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [
      error(CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, 24, 4),
    ]);
  }

  test_invalidConstructorName_notEnclosingClassName_defined() async {
    await assertErrorsInCode(r'''
class A {
  B() : super();
}
class B {}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);
  }

  test_invalidConstructorName_notEnclosingClassName_undefined() async {
    await assertErrorsInCode(r'''
class A {
  B() : super();
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);
  }

  test_invalidFactoryNameNotAClass_notClassName() async {
    await assertErrorsInCode(r'''
int B;
class A {
  factory B() => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 27, 1),
    ]);
  }

  test_invalidFactoryNameNotAClass_notEnclosingClassName() async {
    await assertErrorsInCode(r'''
class A {
  factory B() => null;
}
''', [
      error(CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, 20, 1),
    ]);
  }

  test_invalidIdentifierInAsync_async() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int async;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 5),
    ]);
  }

  test_invalidIdentifierInAsync_await() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int await;
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 5),
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 32, 5),
    ]);
  }

  test_invalidIdentifierInAsync_yield() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int yield;
  }
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 32, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 32, 5),
    ]);
  }

  test_invalidModifierOnConstructor_async() async {
    await assertErrorsInCode(r'''
class A {
  A() async {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, 16, 5),
    ]);
  }

  test_invalidModifierOnConstructor_asyncStar() async {
    await assertErrorsInCode(r'''
class A {
  A() async* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, 16, 5),
    ]);
  }

  test_invalidModifierOnConstructor_syncStar() async {
    await assertErrorsInCode(r'''
class A {
  A() sync* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR, 16, 4),
    ]);
  }

  test_invalidModifierOnSetter_member_async() async {
    // TODO(danrubel): Investigate why error message is duplicated when
    // using fasta parser.
    await assertErrorsInCode(r'''
class A {
  set x(v) async {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 5),
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 5),
    ]);
  }

  test_invalidModifierOnSetter_member_asyncStar() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) async* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 5),
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 5),
    ]);
  }

  test_invalidModifierOnSetter_member_syncStar() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) sync* {}
}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 4),
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 21, 4),
    ]);
  }

  test_invalidModifierOnSetter_topLevel_async() async {
    await assertErrorsInCode('''
set x(v) async {}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 5),
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 5),
    ]);
  }

  test_invalidModifierOnSetter_topLevel_asyncStar() async {
    await assertErrorsInCode('''
set x(v) async* {}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 5),
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 5),
    ]);
  }

  test_invalidModifierOnSetter_topLevel_syncStar() async {
    await assertErrorsInCode('''
set x(v) sync* {}
''', [
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 4),
      error(CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER, 9, 4),
    ]);
  }

  test_invalidTypeArgumentInConstList() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E>[];
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST, 39, 1),
    ]);
  }

  test_invalidTypeArgumentInConstMap() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <String, E>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 47, 1),
    ]);
  }

  test_invalidUri_export() async {
    await assertErrorsInCode('''
export 'ht:';
''', [
      error(CompileTimeErrorCode.INVALID_URI, 7, 5),
    ]);
  }

  test_invalidUri_import() async {
    await assertErrorsInCode('''
import 'ht:';
''', [
      error(CompileTimeErrorCode.INVALID_URI, 7, 5),
    ]);
  }

  test_invalidUri_part() async {
    await assertErrorsInCode(r'''
library lib;
part 'ht:';
''', [
      error(CompileTimeErrorCode.INVALID_URI, 18, 5),
    ]);
  }

  test_isInConstInstanceCreation_restored() async {
    // If ErrorVerifier._isInConstInstanceCreation is not properly restored on
    // exit from visitInstanceCreationExpression, the error at (1) will be
    // treated as a warning rather than an error.
    await assertErrorsInCode(r'''
class Foo<T extends num> {
  const Foo(x, y);
}
const x = const Foo<int>(const Foo<int>(0, 1),
    const <Foo<String>>[]); // (1)
''', [
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 110, 6),
    ]);
  }

  test_isInInstanceVariableInitializer_restored() async {
    // If ErrorVerifier._isInInstanceVariableInitializer is not properly
    // restored on exit from visitVariableDeclaration, the error at (1)
    // won't be detected.
    await assertErrorsInCode(r'''
class Foo {
  var bar;
  Map foo = {
    'bar': () {
        var _bar;
    },
    'bop': _foo // (1)
  };
  _foo() {
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 65, 4),
      error(CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER, 89, 4),
    ]);
  }

  test_labelInOuterScope() async {
    await assertErrorsInCode(r'''
class A {
  void m(int i) {
    l: while (i > 0) {
      void f() {
        break l;
      };
    }
  }
}
''', [
      error(HintCode.UNUSED_ELEMENT, 62, 1),
      error(CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE, 82, 1),
    ]);
  }

  test_labelUndefined_break() async {
    await assertErrorsInCode(r'''
f() {
  x: while (true) {
    break y;
  }
}
''', [
      error(HintCode.UNUSED_LABEL, 8, 2),
      error(CompileTimeErrorCode.LABEL_UNDEFINED, 36, 1),
    ]);
  }

  test_labelUndefined_continue() async {
    await assertErrorsInCode(r'''
f() {
  x: while (true) {
    continue y;
  }
}
''', [
      error(HintCode.UNUSED_LABEL, 8, 2),
      error(CompileTimeErrorCode.LABEL_UNDEFINED, 39, 1),
    ]);
  }

  test_length_of_erroneous_constant() async {
    // Attempting to compute the length of constant that couldn't be evaluated
    // (due to an error) should not crash the analyzer (see dartbug.com/23383)
    await assertErrorsInCode('''
const int i = (1 ? 'alpha' : 'beta').length;
''', [
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 14,
          29),
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 15, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL, 15, 1),
    ]);
  }

  test_memberWithClassName_field() async {
    await assertErrorsInCode(r'''
class A {
  int A = 0;
}
''', [
      error(CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_memberWithClassName_field2() async {
    await assertErrorsInCode(r'''
class A {
  int z, A, b = 0;
}
''', [
      error(CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, 19, 1),
    ]);
  }

  test_memberWithClassName_getter() async {
    await assertErrorsInCode(r'''
class A {
  get A => 0;
}
''', [
      error(CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);
  }

  test_memberWithClassName_method() async {
    // no test because indistinguishable from constructor
  }

  test_mixinClassDeclaresConstructor_classDeclaration() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
class B extends Object with A {}
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 49, 1),
      ],
    );
  }

  test_mixinClassDeclaresConstructor_typeAlias() async {
    await assertErrorsInCode(
      r'''
class A {
  A() {}
}
class B = Object with A;
''',
      [
        error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 43, 1),
      ],
    );
  }

  test_mixinDeferredClass() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B extends Object with a.A {}
''', [
      error(CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, 76, 3),
    ]);
  }

  test_mixinDeferredClass_classTypeAlias() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
class A {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class B {}
class C = B with a.A;
''', [
      error(CompileTimeErrorCode.MIXIN_DEFERRED_CLASS, 76, 3),
    ]);
  }

  test_mixinInference_matchingClass_inPreviousMixin_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M1 implements A<B> {}
mixin M2<T> on A<T> {}
class C extends Object with M1, M2 {}
''');
  }

  test_mixinInference_matchingClass_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends A<int> with M {}
''');
  }

  test_mixinInference_noMatchingClass_namedMixinApplication_new_syntax() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C = Object with M;
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          78, 1),
    ]);
  }

  test_mixinInference_noMatchingClass_new_syntax() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M {}
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          84, 1),
    ]);
  }

  test_mixinInference_noMatchingClass_noSuperclassConstraint_new_syntax() async {
    await assertNoErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> {}
class C extends Object with M {}
''');
  }

  test_mixinInference_noMatchingClass_typeParametersSupplied_new_syntax() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M<int> {}
''', [
      error(CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE,
          84, 1),
    ]);
  }

  test_mixinInference_recursiveSubtypeCheck_new_syntax() async {
    // See dartbug.com/32353 for a detailed explanation.
    await assertNoErrorsInCode('''
class ioDirectory implements ioFileSystemEntity {}

class ioFileSystemEntity {}

abstract class _LocalDirectory
    extends _LocalFileSystemEntity<_LocalDirectory, ioDirectory>
    with ForwardingDirectory, DirectoryAddOnsMixin {}

abstract class _LocalFileSystemEntity<T extends FileSystemEntity,
  D extends ioFileSystemEntity> extends ForwardingFileSystemEntity<T, D> {}

abstract class FileSystemEntity implements ioFileSystemEntity {}

abstract class ForwardingFileSystemEntity<T extends FileSystemEntity,
  D extends ioFileSystemEntity> implements FileSystemEntity {}


mixin ForwardingDirectory<T extends Directory>
    on ForwardingFileSystemEntity<T, ioDirectory>
    implements Directory {}

abstract class Directory implements FileSystemEntity, ioDirectory {}

mixin DirectoryAddOnsMixin implements Directory {}
''');
    var mixins = result.unit.declaredElement.getType('_LocalDirectory').mixins;
    expect(mixins[0].toString(), 'ForwardingDirectory<_LocalDirectory>');
  }

  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 60, 1),
    ]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 72, 1),
    ]);
  }

  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 54, 1),
    ]);
  }

  test_mixinInheritsFromNotObject_typeAlias_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C = Object with B;
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 66, 1),
    ]);
  }

  test_mixinOfDisallowedClass_class_bool() async {
    await assertErrorsInCode('''
class A extends Object with bool {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 4),
    ]);
  }

  test_mixinOfDisallowedClass_class_double() async {
    await assertErrorsInCode('''
class A extends Object with double {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 6),
    ]);
  }

  test_mixinOfDisallowedClass_class_int() async {
    await assertErrorsInCode('''
class A extends Object with int {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 3),
    ]);
  }

  test_mixinOfDisallowedClass_class_Null() async {
    await assertErrorsInCode('''
class A extends Object with Null {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 4),
    ]);
  }

  test_mixinOfDisallowedClass_class_num() async {
    await assertErrorsInCode('''
class A extends Object with num {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 3),
    ]);
  }

  test_mixinOfDisallowedClass_class_String() async {
    await assertErrorsInCode('''
class A extends Object with String {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 6),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with bool;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 4),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with double;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 6),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with int;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 3),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with Null;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 4),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with num;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 3),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with String;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 6),
    ]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_String_num() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with String, num;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 28, 6),
      error(CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS, 36, 3),
    ]);
  }

  test_mixinOfNonClass() async {
    // TODO(brianwilkerson) Compare with MIXIN_WITH_NON_CLASS_SUPERCLASS.
    // TODO(brianwilkerson) Fix the offset and length.
    await assertErrorsInCode(r'''
var A;
class B extends Object mixin A {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 0, 0),
    ]);
  }

  test_mixinOfNonClass_class() async {
    await assertErrorsInCode(r'''
int A;
class B extends Object with A {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 35, 1),
    ]);
  }

  test_mixinOfNonClass_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends Object with E {}
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 43, 1),
    ]);
  }

  test_mixinOfNonClass_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
int B;
class C = A with B;
''', [
      error(CompileTimeErrorCode.MIXIN_OF_NON_CLASS, 35, 1),
    ]);
  }

  test_mixinReferencesSuper() async {
    await assertErrorsInCode(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}
''', [
      error(CompileTimeErrorCode.MIXIN_REFERENCES_SUPER, 74, 1),
    ]);
  }

  test_mixinWithNonClassSuperclass_class() async {
    await assertErrorsInCode(r'''
int A;
class B {}
class C extends A with B {}
''', [
      error(CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS, 34, 1),
    ]);
  }

  test_mixinWithNonClassSuperclass_typeAlias() async {
    await assertErrorsInCode(r'''
int A;
class B {}
class C = A with B;
''', [
      error(CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS, 28, 1),
    ]);
  }

  test_multipleRedirectingConstructorInvocations() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''', [
      error(CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS,
          28, 8),
    ]);
  }

  test_multipleSuperInitializers() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  B() : super(), super() {}
}
''', [
      error(StrongModeCode.INVALID_SUPER_INVOCATION, 39, 7),
      error(CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS, 48, 7),
    ]);
  }

  test_nativeClauseInNonSDKCode() async {
    await assertErrorsInCode('''
class A native 'string' {}
''', [
      error(ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE, 8, 15),
    ]);
  }

  test_nativeFunctionBodyInNonSDKCode_function() async {
    await assertErrorsInCode('''
int m(a) native 'string';
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 9, 16),
    ]);
  }

  test_nativeFunctionBodyInNonSDKCode_method() async {
    await assertErrorsInCode(r'''
class A{
  static int m(a) native 'string';
}
''', [
      error(ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE, 27, 16),
    ]);
  }

  test_noAnnotationConstructorArguments() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
@A
main() {
}
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 25, 2),
    ]);
  }

  test_noDefaultSuperConstructorExplicit() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  B() {}
}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT, 42, 1),
    ]);
  }

  test_noDefaultSuperConstructorImplicit_superHasParameters() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 26, 1),
    ]);
  }

  test_noDefaultSuperConstructorImplicit_superOnlyNamed() async {
    await assertErrorsInCode(r'''
class A { A.named() {} }
class B extends A {}
''', [
      error(CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT, 31, 1),
    ]);
  }

  test_nonConstantAnnotationConstructor_named() async {
    await assertErrorsInCode(r'''
class A {
  A.fromInt() {}
}
@A.fromInt()
main() {
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, 29, 12),
    ]);
  }

  test_nonConstantAnnotationConstructor_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  A() {}
}
@A()
main() {
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR, 21, 4),
    ]);
  }

  test_nonConstantDefaultValue_function_named() async {
    await assertErrorsInCode(r'''
int y;
f({x : y}) {}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 14, 1),
    ]);
  }

  test_nonConstantDefaultValue_function_positional() async {
    await assertErrorsInCode(r'''
int y;
f([x = y]) {}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 14, 1),
    ]);
  }

  test_nonConstantDefaultValue_inConstructor_named() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  A({x : y}) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 28, 1),
    ]);
  }

  test_nonConstantDefaultValue_inConstructor_positional() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  A([x = y]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 28, 1),
    ]);
  }

  test_nonConstantDefaultValue_method_named() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  m({x : y}) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 28, 1),
    ]);
  }

  test_nonConstantDefaultValue_method_positional() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  m([x = y]) {}
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 28, 1),
    ]);
  }

  test_nonConstantDefaultValueFromDeferredLibrary() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V}) {}
''', [
      error(
          CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY,
          55,
          3),
    ]);
  }

  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const V = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V + 1}) {}
''', [
      error(
          CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY,
          55,
          7),
    ]);
  }

  test_nonConstCaseExpression() async {
    await assertErrorsInCode(r'''
f(int p, int q) {
  switch (p) {
    case 3 + q:
      break;
  }
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION, 46, 1),
    ]);
  }

  test_nonConstCaseExpressionFromDeferredLibrary() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c:
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
          87,
          3),
    ]);
  }

  test_nonConstCaseExpressionFromDeferredLibrary_nested() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c + 1:
      break;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY,
          87,
          7),
    ]);
  }

  test_nonConstMapAsExpressionStatement_begin() async {
    // TODO(danrubel): Consider improving recovery
    await assertErrorsInCode(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 9, 3),
      error(ParserErrorCode.EXPECTED_TOKEN, 13, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 13, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 15, 1),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 16, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 16, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 16, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 18, 3),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 22, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 22, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 22, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 24, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);
  }

  test_nonConstMapAsExpressionStatement_only() async {
    // TODO(danrubel): Consider improving recovery
    await assertErrorsInCode(r'''
f() {
  {'a' : 0, 'b' : 1};
}
''', [
      error(ParserErrorCode.EXPECTED_TOKEN, 9, 3),
      error(ParserErrorCode.EXPECTED_TOKEN, 13, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 13, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 15, 1),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 16, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 16, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 16, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 18, 3),
      error(ParserErrorCode.UNEXPECTED_TOKEN, 22, 1),
      error(ParserErrorCode.MISSING_IDENTIFIER, 22, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 22, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 24, 1),
    ]);
  }

  test_nonConstValueInInitializer_assert_condition() async {
    await assertErrorsInCode('''
class A {
  const A(int i) : assert(i.isNegative);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 36, 12),
    ]);
  }

  test_nonConstValueInInitializer_assert_message() async {
    await assertErrorsInCode(r'''
class A {
  const A(int i) : assert(i < 0, 'isNegative = ${i.isNegative}');
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 59, 12),
    ]);
  }

  test_nonConstValueInInitializer_field() async {
    await assertErrorsInCode(r'''
class A {
  static int C;
  final int a;
  const A() : a = C;
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 59, 1),
    ]);
  }

  test_nonConstValueInInitializer_instanceCreation() async {
    // TODO(scheglov): the error CONST_EVAL_THROWS_EXCEPTION is redundant and
    // ought to be suppressed. Or not?
    await assertErrorsInCode(r'''
class A {
  A();
}
class B {
  const B() : a = new A();
  final a;
}
var b = const B();
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 47, 7),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 77, 9),
    ]);
  }

  test_nonConstValueInInitializer_instanceCreation_inDifferentFile() async {
    newFile('/test/lib/a.dart', content: '''
import 'b.dart';
const v = const MyClass();
''');
    await assertErrorsInCode('''
class MyClass {
  const MyClass([p = foo]);
}
''', [
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 37, 3),
      error(CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE, 37, 3),
    ]);
  }

  test_nonConstValueInInitializer_redirecting() async {
    await assertErrorsInCode(r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 71, 1),
    ]);
  }

  test_nonConstValueInInitializer_super() async {
    await assertErrorsInCode(r'''
class A {
  const A(p);
}
class B extends A {
  static var C;
  const B() : super(C);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 82, 1),
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_field() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const int c = 1;''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c;
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 91, 3),
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_field_nested() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 91, 3),
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 103, 3),
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_super() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
const int c = 1;
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
}
''', [
      error(CompileTimeErrorCode.INVALID_CONSTANT, 114, 3),
    ]);
  }

  test_nonGenerativeConstructor_explicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A.named() => null;
}
class B extends A {
  B() : super.named();
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 69, 13),
    ]);
  }

  test_nonGenerativeConstructor_implicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 57, 1),
    ]);
  }

  test_nonGenerativeConstructor_implicit2() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends A {
}
''', [
      error(CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, 41, 1),
    ]);
  }

  test_notEnoughRequiredArguments_const() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
main() {
  const A();
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 48, 2),
    ]);
  }

  test_notEnoughRequiredArguments_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 69, 2),
    ]);
  }

  test_objectCannotExtendAnotherClass() async {
    // TODO(brianwilkerson) Fix the offset and length.
    await assertErrorsInCode(r'''
class Object extends List {}
''', [
      error(CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS, 0, 0),
    ]);
  }

  test_optionalParameterInOperator_named() async {
    await assertErrorsInCode(r'''
class A {
  operator +({p}) {}
}
''', [
      error(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, 24, 1),
    ]);
  }

  test_optionalParameterInOperator_positional() async {
    await assertErrorsInCode(r'''
class A {
  operator +([p]) {}
}
''', [
      error(CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR, 24, 1),
    ]);
  }

  test_partOfNonPart() async {
    newFile("/test/lib/l2.dart", content: '''
library l2;
''');
    await assertErrorsInCode(r'''
library l1;
part 'l2.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 17, 9),
    ]);
  }

  test_partOfNonPart_self() async {
    await assertErrorsInCode(r'''
library lib;
part 'test.dart';
''', [
      error(CompileTimeErrorCode.PART_OF_NON_PART, 18, 11),
    ]);
  }

  test_prefix_assignment_compound_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p += 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 46, 1),
    ]);
  }

  test_prefix_assignment_compound_not_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_prefix_assignment_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p = 1;
  }
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 46, 1),
    ]);
  }

  test_prefix_assignment_not_in_method() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p = 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_prefix_conditionalPropertyAccess_call_loadLibrary() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 41, 1),
    ]);
  }

  test_prefix_conditionalPropertyAccess_get() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p?.x;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 1),
    ]);
  }

  test_prefix_conditionalPropertyAccess_get_loadLibrary() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  return p?.loadLibrary;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 48, 1),
    ]);
  }

  test_prefix_conditionalPropertyAccess_set() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.x = null;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_prefix_conditionalPropertyAccess_set_loadLibrary() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary = null;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 41, 1),
    ]);
  }

  test_prefixCollidesWithTopLevelMembers_functionTypeAlias() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
typedef p();
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 32, 1),
    ]);
  }

  test_prefixCollidesWithTopLevelMembers_topLevelFunction() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
p() {}
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 24, 1),
    ]);
  }

  test_prefixCollidesWithTopLevelMembers_topLevelVariable() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
var p = null;
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 28, 1),
    ]);
  }

  test_prefixCollidesWithTopLevelMembers_type() async {
    newFile("/test/lib/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
class p {}
p.A a;
''', [
      error(CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER, 30, 1),
    ]);
  }

  test_prefixNotFollowedByDot() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 39, 1),
    ]);
  }

  test_prefixNotFollowedByDot_compoundAssignment() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_prefixNotFollowedByDot_conditionalMethodInvocation() async {
    newFile('/test/lib/lib.dart', content: '''
library lib;
g() {}
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.g();
}
''', [
      error(CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT, 32, 1),
    ]);
  }

  test_privateCollisionInClassTypeAlias_mixinAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = Object with A, B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 45, 1),
    ]);
  }

  test_privateCollisionInClassTypeAlias_mixinAndMixin_indirect() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = Object with A;
class D = C with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 62, 1),
    ]);
  }

  test_privateCollisionInClassTypeAlias_superclassAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = A with B;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 37, 1),
    ]);
  }

  test_privateCollisionInClassTypeAlias_superclassAndMixin_same() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = A with A;
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 37, 1),
    ]);
  }

  test_privateCollisionInMixinApplication_mixinAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends Object with A, B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 51, 1),
    ]);
  }

  test_privateCollisionInMixinApplication_mixinAndMixin_indirect() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends Object with A {}
class D extends C with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 76, 1),
    ]);
  }

  test_privateCollisionInMixinApplication_superclassAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends A with B {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 43, 1),
    ]);
  }

  test_privateCollisionInMixinApplication_superclassAndMixin_same() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends A with A {}
''', [
      error(CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION, 43, 1),
    ]);
  }

  test_privateOptionalParameter() async {
    await assertErrorsInCode('''
f({var _p}) {}
''', [
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 3, 6),
    ]);
  }

  test_privateOptionalParameter_fieldFormal() async {
    await assertErrorsInCode(r'''
class A {
  var _p;
  A({this._p: 0});
}
''', [
      error(HintCode.UNUSED_FIELD, 16, 2),
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 25, 7),
    ]);
  }

  test_privateOptionalParameter_withDefaultValue() async {
    await assertErrorsInCode('''
f({_p : 0}) {}
''', [
      error(CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER, 3, 2),
    ]);
  }

  test_recursiveCompileTimeConstant() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  final m = const A();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 31, 1),
    ]);
  }

  test_recursiveCompileTimeConstant_cycle() async {
    await assertErrorsInCode(r'''
const x = y + 1;
const y = x + 1;
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 6, 1),
      error(StrongModeCode.TOP_LEVEL_CYCLE, 10, 1),
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 23, 1),
      error(StrongModeCode.TOP_LEVEL_CYCLE, 27, 1),
    ]);
  }

  test_recursiveCompileTimeConstant_fromMapLiteral() async {
    newFile(
      '/test/lib/constants.dart',
      content: r'''
const int x = y;
const int y = x;
''',
    );
    // No errors, because the cycle is not in this source.
    await assertNoErrorsInCode(r'''
import 'constants.dart';
final z = {x: 0, y: 1};
''');
  }

  test_recursiveCompileTimeConstant_initializer_after_toplevel_var() async {
    await assertErrorsInCode('''
const y = const C();
class C {
  const C() : x = y;
  final x;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 6, 1),
    ]);
  }

  test_recursiveCompileTimeConstant_singleVariable() async {
    await assertErrorsInCode(r'''
const x = x;
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 6, 1),
      error(StrongModeCode.TOP_LEVEL_CYCLE, 10, 1),
    ]);
  }

  test_recursiveCompileTimeConstant_singleVariable_fromConstList() async {
    await assertErrorsInCode(r'''
const elems = const [
  const [
    1, elems, 3,
  ],
];
''', [
      error(CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT, 6, 5),
      error(StrongModeCode.TOP_LEVEL_CYCLE, 39, 5),
    ]);
  }

  test_recursiveConstructorRedirect() async {
    await assertErrorsInCode(r'''
class A {
  A.a() : this.b();
  A.b() : this.a();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, 20, 8),
      error(CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, 40, 8),
    ]);
  }

  test_recursiveConstructorRedirect_directSelfReference() async {
    await assertErrorsInCode(r'''
class A {
  A() : this();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT, 18, 6),
    ]);
  }

  test_recursiveFactoryRedirect() async {
    await assertErrorsInCode(r'''
class A implements B {
  factory A() = C;
}
class B implements C {
  factory B() = A;
}
class C implements A {
  factory C() = B;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 39, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 50, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 83, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 94, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 127, 1),
    ]);
  }

  test_recursiveFactoryRedirect_directSelfReference() async {
    await assertErrorsInCode(r'''
class A {
  factory A() = A;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 26, 1),
    ]);
  }

  test_recursiveFactoryRedirect_diverging() async {
    // Analysis should terminate even though the redirections don't reach a
    // fixed point.  (C<int> redirects to C<C<int>>, then to C<C<C<int>>>, and
    // so on).
    await assertErrorsInCode('''
class C<T> {
  const factory C() = C<C<T>>;
}
main() {
  const C<int>();
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 35, 7),
    ]);
  }

  test_recursiveFactoryRedirect_generic() async {
    await assertErrorsInCode(r'''
class A<T> implements B<T> {
  factory A() = C;
}
class B<T> implements C<T> {
  factory B() = A;
}
class C<T> implements A<T> {
  factory C() = B;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 45, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 56, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 95, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 106, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 145, 1),
    ]);
  }

  test_recursiveFactoryRedirect_named() async {
    await assertErrorsInCode(r'''
class A implements B {
  factory A.nameA() = C.nameC;
}
class B implements C {
  factory B.nameB() = A.nameA;
}
class C implements A {
  factory C.nameC() = B.nameB;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 6, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 45, 7),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 62, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 101, 7),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 118, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 157, 7),
    ]);
  }

  /**
   * "A" references "C" which has cycle with "B". But we should not report problem for "A" - it is
   * not the part of a cycle.
   */
  test_recursiveFactoryRedirect_outsideCycle() async {
    await assertErrorsInCode(r'''
class A {
  factory A() = C;
}
class B implements C {
  factory B() = C;
}
class C implements A, B {
  factory C() = B;
}
''', [
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 37, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 70, 1),
      error(CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE, 81, 1),
      error(CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT, 117, 1),
    ]);
  }

  test_redirectGenerativeToMissingConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.noSuchConstructor();
}
''', [
      error(CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR, 18,
          24),
    ]);
  }

  test_redirectGenerativeToNonGenerativeConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.x();
  factory A.x() => null;
}
''', [
      error(
          CompileTimeErrorCode
              .REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR,
          18,
          8),
    ]);
  }

  test_redirectToMissingConstructor_named() async {
    await assertErrorsInCode(r'''
class A implements B{
  A() {}
}
class B {
  const factory B() = A.name;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 65, 6),
    ]);
  }

  test_redirectToMissingConstructor_unnamed() async {
    await assertErrorsInCode(r'''
class A implements B{
  A.name() {}
}
class B {
  const factory B() = A;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR, 70, 1),
    ]);
  }

  test_redirectToNonClass_notAType() async {
    await assertErrorsInCode(r'''
int A;
class B {
  const factory B() = A;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, 39, 1),
    ]);
  }

  test_redirectToNonClass_undefinedIdentifier() async {
    await assertErrorsInCode(r'''
class B {
  const factory B() = A;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_NON_CLASS, 32, 1),
    ]);
  }

  test_redirectToNonConstConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A.a() {}
  const factory A.b() = A.a;
}
''', [
      error(CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR, 45, 3),
    ]);
  }

  test_referencedBeforeDeclaration_hideInBlock_comment() async {
    await assertNoErrorsInCode(r'''
main() {
  /// [v] is a variable.
  var v = 2;
}
print(x) {}
''');
  }

  test_referencedBeforeDeclaration_hideInBlock_function() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  print(v);
  v() {}
}
print(x) {}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 28, 1,
          expectedMessages: [message('/test/lib/test.dart', 34, 1)]),
    ]);
  }

  test_referencedBeforeDeclaration_hideInBlock_local() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  print(v);
  var v = 2;
}
print(x) {}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 28, 1,
          expectedMessages: [message('/test/lib/test.dart', 38, 1)]),
    ]);
  }

  test_referencedBeforeDeclaration_hideInBlock_subBlock() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  {
    print(v);
  }
  var v = 2;
}
print(x) {}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 34, 1,
          expectedMessages: [message('/test/lib/test.dart', 48, 1)]),
    ]);
  }

  test_referencedBeforeDeclaration_inInitializer_closure() async {
    await assertErrorsInCode(r'''
main() {
  var v = () => v;
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 25, 1,
          expectedMessages: [message('/test/lib/test.dart', 15, 1)]),
    ]);
  }

  test_referencedBeforeDeclaration_inInitializer_directly() async {
    await assertErrorsInCode(r'''
main() {
  var v = v;
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 19, 1,
          expectedMessages: [message('/test/lib/test.dart', 15, 1)]),
    ]);
  }

  test_referencedBeforeDeclaration_type_localFunction() async {
    await assertErrorsInCode(r'''
void testTypeRef() {
  String s = '';
  int String(int x) => x + 1;
  print(s + String);
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 23, 6,
          expectedMessages: [message('/test/lib/test.dart', 44, 6)]),
    ]);
  }

  test_referencedBeforeDeclaration_type_localVariable() async {
    await assertErrorsInCode(r'''
void testTypeRef() {
  String s = '';
  var String = '';
  print(s + String);
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 23, 6,
          expectedMessages: [message('/test/lib/test.dart', 44, 6)]),
    ]);
  }

  test_rethrowOutsideCatch() async {
    await assertErrorsInCode(r'''
f() {
  rethrow;
}
''', [
      error(CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH, 8, 7),
    ]);
  }

  test_returnInGenerativeConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A() { return 0; }
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, 25, 1),
    ]);
  }

  test_returnInGenerativeConstructor_expressionFunctionBody() async {
    await assertErrorsInCode(r'''
class A {
  A() => null;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR, 16, 8),
    ]);
  }

  test_returnInGenerator_asyncStar() async {
    await assertErrorsInCode(r'''
f() async* {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 15, 9),
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 15, 6),
    ]);
  }

  test_returnInGenerator_syncStar() async {
    await assertErrorsInCode(r'''
f() sync* {
  return 0;
}
''', [
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 14, 9),
      error(CompileTimeErrorCode.RETURN_IN_GENERATOR, 14, 6),
    ]);
  }

  test_sharedDeferredPrefix() async {
    newFile('/test/lib/lib1.dart', content: '''
library lib1;
f1() {}
''');
    newFile('/test/lib/lib2.dart', content: '''
library lib2;
f2() {}
''');
    await assertErrorsInCode('''
library root;
import 'lib1.dart' deferred as lib;
import 'lib2.dart' as lib;
main() { lib.f1(); lib.f2(); }
''', [
      error(CompileTimeErrorCode.SHARED_DEFERRED_PREFIX, 33, 8),
    ]);
  }

  test_superInInvalidContext_binaryExpression() async {
    await assertErrorsInCode('''
var v = super + 0;
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 8, 5),
    ]);
  }

  test_superInInvalidContext_constructorFieldInitializer() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  var f;
  B() : f = super.m();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 62, 5),
    ]);
  }

  test_superInInvalidContext_factoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
}
class B extends A {
  factory B() {
    super.m();
    return null;
  }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 61, 5),
    ]);
  }

  test_superInInvalidContext_instanceVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  var a;
}
class B extends A {
 var b = super.a;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 50, 5),
    ]);
  }

  test_superInInvalidContext_staticMethod() async {
    await assertErrorsInCode(r'''
class A {
  static m() {}
}
class B extends A {
  static n() { return super.m(); }
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 70, 5),
    ]);
  }

  test_superInInvalidContext_staticVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  static int a = 0;
}
class B extends A {
  static int b = super.a;
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 69, 5),
    ]);
  }

  test_superInInvalidContext_topLevelFunction() async {
    await assertErrorsInCode(r'''
f() {
  super.f();
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 8, 5),
    ]);
  }

  test_superInInvalidContext_topLevelVariableInitializer() async {
    await assertErrorsInCode('''
var v = super.y;
''', [
      error(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, 8, 5),
    ]);
  }

  test_superInitializerInObject() async {
    await assertErrorsInCode(r'''
class Object {
  Object() : super();
}
''', [
      error(CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT, 0, 0),
    ]);
  }

  test_superInRedirectingConstructor_redirectionSuper() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B() : this.name(), super();
  B.name() {}
}
''', [
      error(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, 42, 7),
    ]);
  }

  test_superInRedirectingConstructor_superRedirection() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B() : super(), this.name();
  B.name() {}
}
''', [
      error(StrongModeCode.INVALID_SUPER_INVOCATION, 29, 7),
      error(CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR, 29, 7),
    ]);
  }

  test_symbol_constructor_badArgs() async {
    await assertErrorsInCode(r'''
var s1 = const Symbol('3');
var s2 = const Symbol(3);
var s3 = const Symbol();
var s4 = const Symbol('x', 'y');
var s5 = const Symbol('x', foo: 'x');
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 9, 17),
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 37, 15),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 50, 1),
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 75, 2),
      error(CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS, 100, 10),
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 139, 3),
    ]);
  }

  test_test_fieldInitializerOutsideConstructor_topLevelFunction() async {
    await assertErrorsInCode(r'''
f(this.x(y)) {}
''', [
      error(CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR, 2, 9),
    ]);
  }

  test_typeAliasCannotReferenceItself_11987() async {
    await assertErrorsInCode(r'''
typedef void F(List<G> l);
typedef void G(List<F> l);
main() {
  F foo(G g) => g;
  foo(null);
}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 26),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 27, 26),
    ]);
  }

  test_typeAliasCannotReferenceItself_19459() async {
    // A complex example involving multiple classes.  This is legal, since
    // typedef F references itself only via a class.
    await assertNoErrorsInCode(r'''
class A<B, C> {}
abstract class D {
  f(E e);
}
abstract class E extends A<dynamic, F> {}
typedef D F();
''');
  }

  test_typeAliasCannotReferenceItself_functionTypedParameter_returnType() async {
    await assertErrorsInCode('''
typedef A(A b());
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 17),
    ]);
  }

  test_typeAliasCannotReferenceItself_generic() async {
    List<ExpectedError> expectedErrors = [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 37),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE, 101, 1),
    ];
    await assertErrorsInCode(r'''
typedef F = void Function(List<G> l);
typedef G = void Function(List<F> l);
main() {
  F foo(G g) => g;
  foo(null);
}
''', expectedErrors);
  }

  test_typeAliasCannotReferenceItself_parameterType_named() async {
    await assertErrorsInCode('''
typedef A({A a});
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 17),
    ]);
  }

  test_typeAliasCannotReferenceItself_parameterType_positional() async {
    await assertErrorsInCode('''
typedef A([A a]);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 17),
    ]);
  }

  test_typeAliasCannotReferenceItself_parameterType_required() async {
    await assertErrorsInCode('''
typedef A(A a);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 15),
    ]);
  }

  test_typeAliasCannotReferenceItself_parameterType_typeArgument() async {
    await assertErrorsInCode('''
typedef A(List<A> a);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 21),
    ]);
  }

  test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() async {
    // A typedef is allowed to indirectly reference itself via a class.
    await assertNoErrorsInCode(r'''
typedef C A();
typedef A B();
class C {
  B a;
}
''');
  }

  test_typeAliasCannotReferenceItself_returnType() async {
    await assertErrorsInCode('''
typedef A A();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 14),
    ]);
  }

  test_typeAliasCannotReferenceItself_returnType_indirect() async {
    await assertErrorsInCode(r'''
typedef B A();
typedef A B();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 14),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 15, 14),
    ]);
  }

  test_typeAliasCannotReferenceItself_typeVariableBounds() async {
    await assertErrorsInCode('''
typedef A<T extends A<int>>();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 30),
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 22, 3),
    ]);
  }

  test_typedef_infiniteParameterBoundCycle() async {
    await assertErrorsInCode(r'''
typedef F<X extends F> = F Function();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 38),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 20, 1),
    ]);
  }

  test_undefinedAnnotation_unresolved_identifier() async {
    await assertErrorsInCode(r'''
@unresolved
main() {
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 11),
    ]);
  }

  test_undefinedAnnotation_unresolved_invocation() async {
    await assertErrorsInCode(r'''
@Unresolved()
main() {
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 13),
    ]);
  }

  test_undefinedAnnotation_unresolved_prefixedIdentifier() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;
@p.unresolved
main() {
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 25, 13),
    ]);
  }

  test_undefinedAnnotation_useLibraryScope() async {
    await assertErrorsInCode(r'''
@foo
class A {
  static const foo = null;
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_ANNOTATION, 0, 4),
    ]);
  }

  test_undefinedClass_const() async {
    await assertErrorsInCode(r'''
f() {
  return const A();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 21, 1),
    ]);
  }

  test_undefinedConstructorInInitializer_explicit_named() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  B() : super.named();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER, 39, 13),
    ]);
  }

  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          55, 7),
    ]);
  }

  test_undefinedConstructorInInitializer_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B();
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
          49, 1),
    ]);
  }

  test_undefinedNamedParameter() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
main() {
  const A(p: 0);
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER, 44, 1),
    ]);
  }

  test_uriDoesNotExist_export() async {
    await assertErrorsInCode('''
export 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_uriDoesNotExist_import() async {
    await assertErrorsInCode('''
import 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 14),
    ]);
  }

  test_uriDoesNotExist_import_appears_after_deleting_target() async {
    String filePath = newFile('/test/lib/target.dart').path;

    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(HintCode.UNUSED_IMPORT, 7, 13),
    ]);

    // Remove the overlay in the same way as AnalysisServer.
    deleteFile(filePath);
    driver.removeFile(filePath);

    await resolveTestFile();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll(result.errors);
    errorListener.assertErrors([
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);
  }

  @failingTest
  test_uriDoesNotExist_import_disappears_when_fixed() async {
    await assertErrorsInCode('''
import 'target.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 7, 13),
    ]);

    newFile('/test/lib/target.dart');

    // Make sure the error goes away.
    // TODO(brianwilkerson) The error does not go away, possibly because the
    //  file is not being reanalyzed.
    await resolveTestFile();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll(result.errors);
    errorListener.assertErrors([
      error(HintCode.UNUSED_IMPORT, 0, 0),
    ]);
  }

  test_uriDoesNotExist_part() async {
    await assertErrorsInCode(r'''
library lib;
part 'unknown.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 18, 14),
    ]);
  }

  test_uriWithInterpolation_constant() async {
    await assertErrorsInCode('''
import 'stuff_\$platform.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 7, 22),
      error(StaticWarningCode.UNDEFINED_IDENTIFIER, 15, 8),
    ]);
  }

  test_uriWithInterpolation_nonConstant() async {
    await assertErrorsInCode(r'''
library lib;
part '${'a'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 18, 13),
    ]);
  }

  test_wrongNumberOfParametersForOperator1() async {
    await _check_wrongNumberOfParametersForOperator1('<');
    await _check_wrongNumberOfParametersForOperator1('>');
    await _check_wrongNumberOfParametersForOperator1('<=');
    await _check_wrongNumberOfParametersForOperator1('>=');
    await _check_wrongNumberOfParametersForOperator1('+');
    await _check_wrongNumberOfParametersForOperator1('/');
    await _check_wrongNumberOfParametersForOperator1('~/');
    await _check_wrongNumberOfParametersForOperator1('*');
    await _check_wrongNumberOfParametersForOperator1('%');
    await _check_wrongNumberOfParametersForOperator1('|');
    await _check_wrongNumberOfParametersForOperator1('^');
    await _check_wrongNumberOfParametersForOperator1('&');
    await _check_wrongNumberOfParametersForOperator1('<<');
    await _check_wrongNumberOfParametersForOperator1('>>');
    await _check_wrongNumberOfParametersForOperator1('[]');
  }

  test_wrongNumberOfParametersForOperator_minus() async {
    await assertErrorsInCode(r'''
class A {
  operator -(a, b) {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS,
          21, 1),
    ]);
  }

  test_wrongNumberOfParametersForOperator_tilde() async {
    await _check_wrongNumberOfParametersForOperator('~', 'a');
    await _check_wrongNumberOfParametersForOperator('~', 'a, b');
  }

  test_wrongNumberOfParametersForSetter_function_named() async {
    await assertErrorsInCode('''
set x({p}) {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 4, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_function_optional() async {
    await assertErrorsInCode('''
set x([p]) {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 4, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_function_tooFew() async {
    await assertErrorsInCode('''
set x() {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 4, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_function_tooMany() async {
    await assertErrorsInCode('''
set x(a, b) {}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 4, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_method_named() async {
    await assertErrorsInCode(r'''
class A {
  set x({p}) {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 16, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_method_optional() async {
    await assertErrorsInCode(r'''
class A {
  set x([p]) {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 16, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_method_tooFew() async {
    await assertErrorsInCode(r'''
class A {
  set x() {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 16, 1),
    ]);
  }

  test_wrongNumberOfParametersForSetter_method_tooMany() async {
    await assertErrorsInCode(r'''
class A {
  set x(a, b) {}
}
''', [
      error(CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER, 16, 1),
    ]);
  }

  test_yield_used_as_identifier_in_async_method() async {
    await assertErrorsInCode('''
f() async {
  var yield = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }

  test_yield_used_as_identifier_in_async_star_method() async {
    await assertErrorsInCode('''
f() async* {
  var yield = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 19, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 5),
    ]);
  }

  test_yield_used_as_identifier_in_sync_star_method() async {
    await assertErrorsInCode('''
f() sync* {
  var yield = 1;
}
''', [
      error(ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER, 18, 5),
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 5),
    ]);
  }

  test_yieldEachInNonGenerator_async() async {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    await assertErrorsInCode(r'''
f() async {
  yield* 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR, 0, 0),
    ]);
  }

  test_yieldEachInNonGenerator_sync() async {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    await assertErrorsInCode(r'''
f() {
  yield* 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_IN_NON_GENERATOR, 0, 0),
    ]);
  }

  test_yieldInNonGenerator_async() async {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    await assertErrorsInCode(r'''
f() async {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_IN_NON_GENERATOR, 0, 0),
    ]);
  }

  test_yieldInNonGenerator_sync() async {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    await assertErrorsInCode(r'''
f() {
  yield 0;
}
''', [
      error(CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR, 0, 0),
    ]);
  }

  Future<void> _check_constEvalThrowsException_binary_null(
      String expr, bool resolved) async {
    await assertErrorsInCode('''
const dynamic D = null;
const C = ${expr.replaceAll('null', 'D')};
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 34, 5),
    ]);
  }

  Future<void> _check_constEvalTypeBoolOrInt_binary(String expr) async {
    await assertErrorsInCode('''
const int a = 0;
const _ = $expr;
''', [
      error(HintCode.UNUSED_ELEMENT, 23, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT, 27, 6),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 2),
    ]);
  }

  Future<void> _check_constEvalTypeInt_binary(String expr) async {
    await assertErrorsInCode('''
const int a = 0;
const _ = $expr;
''', [
      error(HintCode.UNUSED_ELEMENT, 23, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT, 27, 6),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 2),
    ]);
  }

  Future<void> _check_constEvalTypeNum_binary(String expr) async {
    await assertErrorsInCode('''
const num a = 0;
const _ = $expr;
''', [
      error(HintCode.UNUSED_ELEMENT, 23, 1),
      error(CompileTimeErrorCode.CONST_EVAL_TYPE_NUM, 27, 6),
      error(StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE, 31, 2),
    ]);
  }

  Future<void> _check_wrongNumberOfParametersForOperator(
      String name, String parameters) async {
    await assertErrorsInCode('''
class A {
  operator $name($parameters) {}
}
''', [
      error(
          CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR, 21, 1),
    ]);
  }

  Future<void> _check_wrongNumberOfParametersForOperator1(String name) async {
    await _check_wrongNumberOfParametersForOperator(name, '');
    await _check_wrongNumberOfParametersForOperator(name, 'a, b');
  }

  Future<void> _privateCollisionInMixinApplicationTest(
      String testCode, List<ExpectedError> expectedErrors) async {
    newFile('/test/lib/lib1.dart', content: '''
class A {
  int _x;
}

class B {
  int _x;
}
''');
    await assertErrorsInCode(testCode, expectedErrors);
  }
}
