// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test/test.dart' show expect;

import 'resolver_test_case.dart';

class CompileTimeErrorCodeTestBase extends ResolverTestCase {
  disabled_test_conflictingGenericInterfaces_hierarchyLoop_infinite() async {
    // There is an interface conflict here due to a loop in the class
    // hierarchy leading to an infinite set of implemented types; this loop
    // shouldn't cause non-termination.

    // TODO(paulberry): this test is currently disabled due to non-termination
    // bugs elsewhere in the analyzer.
    await assertErrorsInCode('''
class A<T> implements B<List<T>> {}
class B<T> implements A<List<T>> {}
''', [CompileTimeErrorCode.CONFLICTING_GENERIC_INTERFACES]);
  }

  test_accessPrivateEnumField() async {
    await assertErrorsInCode(r'''
enum E { ONE }
String name(E e) {
  return e._name;
}
''', [CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD], verify: false);
  }

  test_ambiguousExport() async {
    newFile("/lib1.dart", content: r'''
library lib1;
class N {}
''');
    newFile("/lib2.dart", content: r'''
library lib2;
class N {}
''');
    await assertErrorsInCode(r'''
library L;
export 'lib1.dart';
export 'lib2.dart';
''', [CompileTimeErrorCode.AMBIGUOUS_EXPORT]);
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
''', [CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS]);
  }

  test_annotationWithNotClass_prefixed() async {
    newFile("/annotations.dart", content: r'''
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
''', [CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS]);
  }

  test_asyncForInWrongContext() async {
    await assertErrorsInCode(r'''
f(list) {
  await for (var e in list) {
  }
}
''', [CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT]);
  }

  test_awaitInWrongContext_sync() async {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    await assertErrorsInCode(r'''
f(x) {
  return await x;
}
''', [CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT]);
  }

  test_awaitInWrongContext_syncStar() async {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    await assertErrorsInCode(r'''
f(x) sync* {
  yield await x;
}
''', [CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT]);
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
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
  }

  test_builtInIdentifierAsMixinName_classTypeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class as = A with B;
''', [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
  }

  test_builtInIdentifierAsPrefixName() async {
    await assertErrorsInCode('''
import 'dart:async' as abstract;
''', [
      CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME,
      HintCode.UNUSED_IMPORT
    ]);
  }

  test_builtInIdentifierAsType_dynamicMissingPrefix() async {
    await assertErrorsInCode('''
import 'dart:core' as core;

dynamic x;
''', [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
  }

  test_builtInIdentifierAsType_formalParameter_field() async {
    await assertErrorsInCode(r'''
class A {
  var x;
  A(static this.x);
}
''', [ParserErrorCode.EXTRANEOUS_MODIFIER]);
  }

  test_builtInIdentifierAsType_formalParameter_simple() async {
    await assertErrorsInCode(r'''
f(static x) {
}
''', [ParserErrorCode.EXTRANEOUS_MODIFIER]);
  }

  test_builtInIdentifierAsType_variableDeclaration() async {
    await assertErrorsInCode(r'''
f() {
  typedef x;
}
''', [
      StaticWarningCode.UNDEFINED_IDENTIFIER,
      StaticWarningCode.UNDEFINED_IDENTIFIER,
      ParserErrorCode.EXPECTED_TOKEN
    ]);
  }

  test_builtInIdentifierAsTypedefName_functionTypeAlias() async {
    await assertErrorsInCode('''
typedef bool as();
''', [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
  }

  test_builtInIdentifierAsTypeName() async {
    await assertErrorsInCode('''
class as {}
''', [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME]);
  }

  test_builtInIdentifierAsTypeParameterName() async {
    await assertErrorsInCode('''
class A<as> {}
''', [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME]);
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
''', [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
  }

  test_conflictingGenericInterfaces_hierarchyLoop() async {
    // There is no interface conflict here, but there is a loop in the class
    // hierarchy leading to a finite set of implemented types; this loop
    // shouldn't cause non-termination.
    await assertErrorsInCode('''
class A<T> implements B<T> {}
class B<T> implements A<T> {}
''', [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
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
''', [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS]);
  }

  test_conflictingTypeVariableAndMember_field() async {
    await assertErrorsInCode(r'''
class A<T> {
  var T;
}
''', [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
  }

  test_conflictingTypeVariableAndMember_getter() async {
    await assertErrorsInCode(r'''
class A<T> {
  get T => null;
}
''', [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
  }

  test_conflictingTypeVariableAndMember_method() async {
    await assertErrorsInCode(r'''
class A<T> {
  T() {}
}
''', [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
  }

  test_conflictingTypeVariableAndMember_method_static() async {
    await assertErrorsInCode(r'''
class A<T> {
  static T() {}
}
''', [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
  }

  test_conflictingTypeVariableAndMember_setter() async {
    await assertErrorsInCode(r'''
class A<T> {
  set T(x) {}
}
''', [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
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
    newFile('/lib.dart', content: r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    await assertErrorsInCode(r'''
import 'lib.dart';
const a = const A();
''', [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
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
    // TODO(paulberry): the error CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE is
    // redundant and ought to be suppressed.
    await assertErrorsInCode(r'''
class A {
  final int i = f();
  const A();
}
int f() {
  return 3;
}
''', [
      CompileTimeErrorCode
          .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
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
''', [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
  }

  test_constConstructorWithNonConstSuper_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A();
}
class B extends A {
  const B();
}
''', [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
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
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN_WITH_FIELD,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
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
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER
    ]);
  }

  test_constConstructorWithNonFinalField_this() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  const A();
}
''', [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
  }

  test_constDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {
  const A();
}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A();
}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.CONST_DEFERRED_CLASS
    ]);
  }

  test_constDeferredClass_namedConstructor() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {
  const A.b();
}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A.b();
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.CONST_DEFERRED_CLASS
    ]);
  }

  test_constEval_newInstance_constConstructor() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
const a = new A();
''', [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
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
''', [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  test_constEval_propertyExtraction_targetNotConst() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  int m() => 0;
}
final a = const A();
const C = a.m;
''', [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  test_constEvalThrowsException() async {
    await assertErrorsInCode(r'''
class C {
  const C();
}
f() { return const C(); }
''', [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION]);
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
''', [CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE]);
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
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION
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
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
    ]);
  }

  test_constEvalThrowsException_unaryBitNot_null() async {
    await assertErrorsInCode('''
const C = ~null;
''', [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION], verify: false);
  }

  test_constEvalThrowsException_unaryNegated_null() async {
    await assertErrorsInCode('''
const C = -null;
''', [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION], verify: false);
  }

  test_constEvalThrowsException_unaryNot_null() async {
    await assertErrorsInCode('''
const C = !null;
''', [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
  }

  test_constEvalTypeBool_binary_and() async {
    await assertErrorsInCode('''
const _ = true && '';
''', [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_OPERAND,
    ]);
  }

  test_constEvalTypeBool_binary_leftTrue() async {
    await assertErrorsInCode('''
const C = (true || 0);
''', [StaticTypeWarningCode.NON_BOOL_OPERAND, HintCode.DEAD_CODE]);
  }

  test_constEvalTypeBool_binary_or() async {
    await assertErrorsInCode(r'''
const _ = false || '';
''', [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_OPERAND,
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
    await assertErrorsInCode(r'''
class A {
  const A();
}

const num a = 0;
const _ = a == const A();
''', [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
  }

  test_constEvalTypeBoolNumString_notEqual() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}

const num a = 0;
const _ = a != const A();
''', [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
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
      CompileTimeErrorCode.CONST_FORMAL_PARAMETER,
      ParserErrorCode.EXTRANEOUS_MODIFIER
    ]);
  }

  test_constFormalParameter_simpleFormalParameter() async {
    await assertErrorsInCode('''
f(const x) {}
''', [
      CompileTimeErrorCode.CONST_FORMAL_PARAMETER,
      ParserErrorCode.EXTRANEOUS_MODIFIER
    ]);
  }

  test_constInitializedWithNonConstValue() async {
    await assertErrorsInCode(r'''
f(p) {
  const C = p;
}
''', [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
  }

  test_constInitializedWithNonConstValue_finalField() async {
    // Regression test for bug #25526 which previously
    // caused two errors to be reported.
    await assertErrorsInCode(r'''
class Foo {
  final field = 0;
  foo([int x = field]) {}
}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
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
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V;
'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_constInitializedWithNonConstValueFromDeferredClass_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V + 1;
'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_constInstanceField() async {
    await assertErrorsInCode(r'''
class C {
  const int f = 0;
}
''', [CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
  }

  test_constWithInvalidTypeParameters() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
f() { return const A<A>(); }
''', [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
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
''', [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
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
''', [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
  }

  test_constWithNonConst() async {
    await assertErrorsInCode(r'''
class T {
  T(a, b, {c, d}) {}
}
f() { return const T(0, 1, c: 2, d: 3); }
''', [CompileTimeErrorCode.CONST_WITH_NON_CONST]);
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
''', [CompileTimeErrorCode.CONST_WITH_NON_CONST]);
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
''', [CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT]);
  }

  test_constWithNonConstantArgument_instanceCreation() async {
    await assertErrorsInCode(r'''
class A {
  const A(a);
}
f(p) { return const A(p); }
''', [
      CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT,
    ]);
  }

  test_constWithNonType() async {
    await assertErrorsInCode(r'''
int A;
f() {
  return const A();
}
''', [CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
  }

  test_constWithNonType_fromLibrary() async {
    Source source1 = addNamedSource("/lib.dart", '');
    Source source2 = addNamedSource("/lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  const lib.A();
}
''');
    await computeAnalysisResult(source1);
    await computeAnalysisResult(source2);
    assertErrors(source2, [CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source1]);
  }

  test_constWithTypeParameters_direct() async {
    await assertErrorsInCode(r'''
class A<T> {
  static const V = const A<T>();
  const A();
}
''', [
      CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
      StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC
    ]);
  }

  test_constWithTypeParameters_indirect() async {
    await assertErrorsInCode(r'''
class A<T> {
  static const V = const A<List<T>>();
  const A();
}
''', [
      CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
      StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC
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
''', [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR], verify: false);
  }

  test_constWithUndefinedConstructorDefault() async {
    await assertErrorsInCode(r'''
class A {
  const A.name();
}
f() {
  return const A();
}
''', [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
  }

  test_defaultValueInFunctionTypeAlias_new_named() async {
    await assertErrorsInCode('''
typedef F = int Function({Map<String, String> m: const {}});
''', [
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE,
    ]);
  }

  test_defaultValueInFunctionTypeAlias_new_positional() async {
    await assertErrorsInCode('''
typedef F = int Function([Map<String, String> m = const {}]);
''', [
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE,
    ]);
  }

  test_defaultValueInFunctionTypeAlias_old_named() async {
    await assertErrorsInCode('''
typedef F([x = 0]);
''', [
      CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS,
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE
    ]);
  }

  test_defaultValueInFunctionTypeAlias_old_positional() async {
    await assertErrorsInCode('''
typedef F([x = 0]);
''', [
      CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS,
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE
    ]);
  }

  test_defaultValueInFunctionTypedParameter_named() async {
    await assertErrorsInCode('''
f(g({p: null})) {}
''', [
      CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER,
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE
    ]);
  }

  test_defaultValueInFunctionTypedParameter_optional() async {
    await assertErrorsInCode('''
f(g([p = null])) {}
''', [
      CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER,
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE
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
''', [CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR]);
  }

  test_deferredImportWithInvalidUri() async {
    await assertErrorsInCode(r'''
import '[invalid uri]' deferred as p;
main() {
  p.loadLibrary();
}
''', [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_duplicateDefinition_acrossLibraries() async {
    Source librarySource = addNamedSource("/lib.dart", r'''
library lib;

part 'a.dart';
part 'b.dart';
''');
    Source sourceA = addNamedSource("/a.dart", r'''
part of lib;

class A {}
''');
    Source sourceB = addNamedSource("/b.dart", r'''
part of lib;

class A {}
''');
    await computeAnalysisResult(librarySource);
    await computeAnalysisResult(sourceA);
    await computeAnalysisResult(sourceB);
    assertNoErrors(librarySource);
    assertErrors(sourceB, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA, sourceB]);
  }

  test_duplicateDefinition_catch() async {
    await assertErrorsInCode(r'''
main() {
  try {} catch (e, e) {}
}''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_inPart() async {
    Source librarySource = addNamedSource("/lib.dart", r'''
library test;
part 'a.dart';
class A {}
''');
    Source sourceA = addNamedSource("/a.dart", r'''
part of test;
class A {}
''');
    await computeAnalysisResult(librarySource);
    await computeAnalysisResult(sourceA);
    assertNoErrors(librarySource);
    assertErrors(sourceA, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA]);
  }

  test_duplicateDefinition_locals_inCase() async {
    await assertErrorsInCode(r'''
main() {
  switch(1) {
    case 1:
      var a;
      var a;
  }
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_locals_inFunctionBlock() async {
    await assertErrorsInCode(r'''
main() {
  int m = 0;
  m(a) {}
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_locals_inIf() async {
    await assertErrorsInCode(r'''
main(int p) {
  if (p != 0) {
    var a;
    var a;
  }
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_locals_inMethodBlock() async {
    await assertErrorsInCode(r'''
class A {
  m() {
    int a;
    int a;
  }
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_parameters_inConstructor() async {
    await assertErrorsInCode(r'''
class A {
  int a;
  A(int a, this.a);
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_parameters_inFunctionTypeAlias() async {
    await assertErrorsInCode(r'''
typedef F(int a, double a);
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_parameters_inLocalFunction() async {
    await assertErrorsInCode(r'''
main() {
  f(int a, double a) {
  };
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_parameters_inMethod() async {
    await assertErrorsInCode(r'''
class A {
  m(int a, double a) {
  }
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_parameters_inTopLevelFunction() async {
    await assertErrorsInCode(r'''
f(int a, double a) {}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateDefinition_typeParameters() async {
    await assertErrorsInCode(r'''
class A<T, T> {}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
  }

  test_duplicateNamedArgument() async {
    await assertErrorsInCode(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}
''', [CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT]);
  }

  test_duplicatePart_sameSource() async {
    newFile('/part.dart', content: 'part of lib;');
    await assertErrorsInCode(r'''
library lib;
part 'part.dart';
part 'foo/../part.dart';
''', [CompileTimeErrorCode.DUPLICATE_PART]);
  }

  test_duplicatePart_sameUri() async {
    newFile('/part.dart', content: 'part of lib;');
    await assertErrorsInCode(r'''
library lib;
part 'part.dart';
part 'part.dart';
''', [CompileTimeErrorCode.DUPLICATE_PART]);
  }

  test_exportInternalLibrary() async {
    await assertErrorsInCode('''
export 'dart:_interceptors';
''', [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY]);
  }

  test_exportOfNonLibrary() async {
    newFile("/lib1.dart", content: '''
part of lib;
''');
    await assertErrorsInCode(r'''
library L;
export 'lib1.dart';
''', [CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
  }

  test_extendsDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B extends a.A {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS
    ]);
  }

  test_extendsDeferredClass_classTypeAlias() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class M {}
class C = a.A with M;
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS
    ]);
  }

  test_extendsDisallowedClass_class_bool() async {
    await assertErrorsInCode('''
class A extends bool {}
''', [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
  }

  test_extendsDisallowedClass_class_double() async {
    await assertErrorsInCode('''
class A extends double {}
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_class_int() async {
    await assertErrorsInCode('''
class A extends int {}
''', [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
  }

  test_extendsDisallowedClass_class_Null() async {
    await assertErrorsInCode('''
class A extends Null {}
''', [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
  }

  test_extendsDisallowedClass_class_num() async {
    await assertErrorsInCode('''
class A extends num {}
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_class_String() async {
    await assertErrorsInCode('''
class A extends String {}
''', [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
  }

  test_extendsDisallowedClass_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class M {}
class C = bool with M;
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class M {}
class C = double with M;
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class M {}
class C = int with M;
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class M {}
class C = Null with M;
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class M {}
class C = num with M;
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extendsDisallowedClass_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class M {}
class C = String with M;
''', [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
  }

  test_extraPositionalArguments_const() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
main() {
  const A(0);
}
''', [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
  }

  test_extraPositionalArguments_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
}
''', [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
  }

  test_extraPositionalArgumentsCouldBeNamed_const() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x});
}
main() {
  const A(0);
}
''', [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED]);
  }

  test_extraPositionalArgumentsCouldBeNamed_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A({int x});
}
class B extends A {
  const B() : super(0);
}
''', [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED]);
  }

  test_fieldFormalParameter_assignedInInitializer() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x) : x = 3 {}
}
''', [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
  }

  test_fieldInitializedByMultipleInitializers() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1 {}
}
''', [CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
  }

  test_fieldInitializedByMultipleInitializers_multipleInits() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A() : x = 0, x = 1, x = 2 {}
}
''', [
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS
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
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS
    ]);
  }

  test_fieldInitializedInParameterAndInitializer() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(this.x) : x = 1 {}
}
''', [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
  }

  test_fieldInitializerFactoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  factory A(this.x) => null;
}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR]);
  }

  test_fieldInitializerOutsideConstructor() async {
    // TODO(brianwilkerson) Fix the duplicate error messages.
    await assertErrorsInCode(r'''
class A {
  int x;
  m(this.x) {}
}
''', [
      ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
      CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
    ]);
  }

  test_fieldInitializerOutsideConstructor_defaultParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  m([this.x]) {}
}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
  }

  test_fieldInitializerOutsideConstructor_inFunctionTypeParameter() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A(int p(this.x));
}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
  }

  test_fieldInitializerRedirectingConstructor_afterRedirection() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A.named() {}
  A() : this.named(), x = 42;
}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
  }

  test_fieldInitializerRedirectingConstructor_beforeRedirection() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A.named() {}
  A() : x = 42, this.named();
}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
  }

  test_fieldInitializingFormalRedirectingConstructor() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  A.named() {}
  A(this.x) : this.named();
}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
  }

  test_finalInitializedMultipleTimes_initializers() async {
    await assertErrorsInCode(r'''
class A {
  final x;
  A() : x = 0, x = 0 {}
}
''', [CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
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
''', [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
  }

  test_finalInitializedMultipleTimes_initializingFormals() async {
    // TODO(brianwilkerson) There should only be one error here.
    await assertErrorsInCode(r'''
class A {
  final x;
  A(this.x, this.x) {}
}
''', [
      CompileTimeErrorCode.DUPLICATE_DEFINITION,
      CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES
    ]);
  }

  test_finalNotInitialized_instanceField_const_static() async {
    await assertErrorsInCode(r'''
class A {
  static const F;
}
''', [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
  }

  test_finalNotInitialized_library_const() async {
    await assertErrorsInCode('''
const F;
''', [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
  }

  test_finalNotInitialized_local_const() async {
    await assertErrorsInCode(r'''
f() {
  const int x;
}
''', [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
  }

  test_forInWithConstVariable_forEach_identifier() async {
    await assertErrorsInCode(r'''
f() {
  const x = 0;
  for (x in [0, 1, 2]) {}
}
''', [CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE]);
  }

  test_forInWithConstVariable_forEach_loopVariable() async {
    await assertErrorsInCode(r'''
f() {
  for (const x in [0, 1, 2]) {}
}
''', [CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE]);
  }

  test_fromEnvironment_bool_badArgs() async {
    await assertErrorsInCode(r'''
var b1 = const bool.fromEnvironment(1);
var b2 = const bool.fromEnvironment('x', defaultValue: 1);
''', [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    driver.declaredVariables = new DeclaredVariables.fromMap({'x': 'true'});
    Source source = addSource('''
var b = const bool.fromEnvironment('x', defaultValue: 1);
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  test_genericFunctionTypeArgument_inference_function() async {
    await assertErrorsInCode(r'''
T f<T>(T t) => null;
main() { f(<S>(S s) => s); }
''', [StrongModeCode.COULD_NOT_INFER]);
  }

  test_genericFunctionTypeArgument_inference_functionType() async {
    await assertErrorsInCode(r'''
T Function<T>(T) f;
main() { f(<S>(S s) => s); }
''', [StrongModeCode.COULD_NOT_INFER]);
  }

  test_genericFunctionTypeArgument_inference_method() async {
    await assertErrorsInCode(r'''
class C {
  T f<T>(T t) => null;
}
main() { new C().f(<S>(S s) => s); }
''', [StrongModeCode.COULD_NOT_INFER]);
  }

  test_genericFunctionTypeAsBound_class() async {
    await assertErrorsInCode(r'''
class C<T extends S Function<S>(S)> {
}
''', [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND]);
  }

  test_genericFunctionTypeAsBound_genericFunction() async {
    await assertErrorsInCode(r'''
T Function<T extends S Function<S>(S)>(T) fun;
''', [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND]);
  }

  test_genericFunctionTypeAsBound_genericFunctionTypedef() async {
    await assertErrorsInCode(r'''
typedef foo = T Function<T extends S Function<S>(S)>(T t);
''', [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND]);
  }

  test_genericFunctionTypeAsBound_parameterOfFunction() async {
    await assertNoErrorsInCode(r'''
class C<T extends void Function(S Function<S>(S))> {}
''');
  }

  test_genericFunctionTypeAsBound_typedef() async {
    await assertErrorsInCode(r'''
typedef T foo<T extends S Function<S>(S)>(T t);
''', [CompileTimeErrorCode.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND]);
  }

  test_genericFunctionTypedParameter() async {
    // Once dartbug.com/28515 is fixed, this syntax should no longer generate an
    // error.
    // TODO(paulberry): When dartbug.com/28515 is fixed, convert this into a
    // NonErrorResolverTest.
    await assertErrorsInCode('''
void g(T f<T>(T x)) {}
''', [
      CompileTimeErrorCode.GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED,
      // Due to dartbug.com/28515, some additional errors appear when using the
      // new analysis driver.
      StaticWarningCode.UNDEFINED_CLASS, StaticWarningCode.UNDEFINED_CLASS
    ]);
  }

  test_implementsDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B implements a.A {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS
    ]);
  }

  test_implementsDeferredClass_classTypeAlias() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B {}
class M {}
class C = B with M implements a.A;
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS
    ]);
  }

  test_implementsDisallowedClass_class_bool() async {
    await assertErrorsInCode('''
class A implements bool {}
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_class_double() async {
    await assertErrorsInCode('''
class A implements double {}
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_class_int() async {
    await assertErrorsInCode('''
class A implements int {}
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_class_Null() async {
    await assertErrorsInCode('''
class A implements Null {}
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_class_num() async {
    await assertErrorsInCode('''
class A implements num {}
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_class_String() async {
    await assertErrorsInCode('''
class A implements String {}
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_class_String_num() async {
    await assertErrorsInCode('''
class A implements String, num {}
''', [
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS
    ]);
  }

  test_implementsDisallowedClass_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements bool;
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements double;
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements int;
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements Null;
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements num;
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements String;
''', [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
  }

  test_implementsDisallowedClass_classTypeAlias_String_num() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class C = A with M implements String, num;
''', [
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS
    ]);
  }

  test_implementsNonClass_class() async {
    await assertErrorsInCode(r'''
int A;
class B implements A {}
''', [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
  }

  test_implementsNonClass_dynamic() async {
    await assertErrorsInCode('''
class A implements dynamic {}
''', [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
  }

  test_implementsNonClass_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A implements E {}
''', [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
  }

  test_implementsNonClass_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
int B;
class C = A with M implements B;
''', [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
  }

  test_implementsSuperClass() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A implements A {}
''', [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
  }

  test_implementsSuperClass_Object() async {
    await assertErrorsInCode('''
class A implements Object {}
''', [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
  }

  test_implementsSuperClass_Object_typeAlias() async {
    await assertErrorsInCode(r'''
class M {}
class A = Object with M implements Object;
''', [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
  }

  test_implementsSuperClass_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
class M {}
class B = A with M implements A;
''', [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
  }

  test_implicitThisReferenceInInitializer_field() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  A() : v = f;
  var f;
}
''', [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
  }

  test_implicitThisReferenceInInitializer_field2() async {
    await assertErrorsInCode(r'''
class A {
  final x = 0;
  final y = x;
}
''', [
      CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER,
      StrongModeCode.TOP_LEVEL_INSTANCE_GETTER
    ]);
  }

  test_implicitThisReferenceInInitializer_invocation() async {
    await assertErrorsInCode(r'''
class A {
  var v;
  A() : v = f();
  f() {}
}
''', [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
  }

  test_implicitThisReferenceInInitializer_invocationInStatic() async {
    await assertErrorsInCode(r'''
class A {
  static var F = m();
  int m() => 0;
}
''', [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
  }

  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    await assertErrorsInCode(r'''
class A {
  A(p) {}
  A.named() : this(f);
  var f;
}
''', [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
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
''', [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
  }

  test_importInternalLibrary() async {
    // Note, in these error cases we may generate an UNUSED_IMPORT hint, while
    // we could prevent the hint from being generated by testing the import
    // directive for the error, this is such a minor corner case that we don't
    // think we should add the additional computation time to figure out such
    // cases.
    await assertErrorsInCode('''
import 'dart:_interceptors';
''', [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, HintCode.UNUSED_IMPORT]);
  }

  test_importOfNonLibrary() async {
    newFile("/part.dart", content: r'''
part of lib;
class A{}
''');
    await assertErrorsInCode(r'''
library lib;
import 'part.dart';
A a;
''', [CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
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
''', [CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
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
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES
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
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES
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
''', [CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD], verify: false);
  }

  test_initializerForNonExistent_initializer() async {
    await assertErrorsInCode(r'''
class A {
  A() : x = 0 {}
}
''', [CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD], verify: false);
  }

  test_initializerForStaticField() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
  A() : x = 0 {}
}
''', [CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD]);
  }

  test_initializingFormalForNonExistentField() async {
    await assertErrorsInCode(r'''
class A {
  A(this.x) {}
}
''', [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
  }

  test_initializingFormalForNonExistentField_notInEnclosingClass() async {
    await assertErrorsInCode(r'''
class A {
int x;
}
class B extends A {
  B(this.x) {}
}
''', [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
  }

  test_initializingFormalForNonExistentField_optional() async {
    await assertErrorsInCode(r'''
class A {
  A([this.x]) {}
}
''', [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
  }

  test_initializingFormalForNonExistentField_synthetic() async {
    await assertErrorsInCode(r'''
class A {
  int get x => 1;
  A(this.x) {}
}
''', [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
  }

  test_initializingFormalForStaticField() async {
    await assertErrorsInCode(r'''
class A {
  static int x;
  A([this.x]) {}
}
''', [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD]);
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
''', [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY]);
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
''', [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY]);
  }

  test_instanceMemberAccessFromStatic_field() async {
    await assertErrorsInCode(r'''
class A {
  int f;
  static foo() {
    f;
  }
}
''', [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
  }

  test_instanceMemberAccessFromStatic_getter() async {
    await assertErrorsInCode(r'''
class A {
  get g => null;
  static foo() {
    g;
  }
}
''', [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
  }

  test_instanceMemberAccessFromStatic_method() async {
    await assertErrorsInCode(r'''
class A {
  m() {}
  static foo() {
    m();
  }
}
''', [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
  }

  test_instantiate_to_bounds_not_matching_bounds() async {
    Source source = addSource('''
class Foo<T> {}
class Bar<T extends Foo<T>> {}
class Baz extends Bar {}
void main() {}
''');
    var result = await computeAnalysisResult(source);
    // Instantiate-to-bounds should have instantiated "Bar" to "Bar<Foo>"
    expect(result.unit.declaredElement.getType('Baz').supertype.toString(),
        'Bar<Foo<dynamic>>');
    // Therefore there should be an error, since Bar's type argument T is Foo,
    // which doesn't extends Foo<T>.
    assertErrors(
        source, [StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  test_instantiateEnum_const() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e(String name) {
  return const E();
}
''', [CompileTimeErrorCode.INSTANTIATE_ENUM]);
  }

  test_instantiateEnum_new() async {
    await assertErrorsInCode(r'''
enum E { ONE }
E e(String name) {
  return new E();
}
''', [CompileTimeErrorCode.INSTANTIATE_ENUM]);
  }

  test_integerLiteralAsDoubleOutOfRange_excessiveExponent() async {
    Source source = addSource(
        'double x = 0xfffffffffffff80000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000000000000'
        '000000000000000000000000000000000000000000000000000000000000;');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE]);
    AnalysisError error = analysisResults[source].errors[0];

    // Check that we suggest the max double instead.
    expect(
        true,
        error.correction.contains(
            '179769313486231570814527423731704356798070567525844996598917476803'
            '157260780028538760589558632766878171540458953514382464234321326889'
            '464182768467546703537516986049910576551282076245490090389328944075'
            '868508455133942304583236903222948165808559332123348274797826204144'
            '723168738177180919299881250404026184124858368'));
  }

  test_integerLiteralAsDoubleOutOfRange_excessiveMantissa() async {
    Source source = addSource('''
double x = 9223372036854775809;
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INTEGER_LITERAL_IMPRECISE_AS_DOUBLE]);
    AnalysisError error = analysisResults[source].errors[0];
    // Check that we suggest a valid double instead.
    expect(true, error.correction.contains('9223372036854775808'));
  }

  test_integerLiteralOutOfRange_negative() async {
    await assertErrorsInCode('''
int x = -9223372036854775809;
''', [CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE]);
  }

  test_integerLiteralOutOfRange_positive() async {
    await assertErrorsInCode('''
int x = 9223372036854775808;
''', [CompileTimeErrorCode.INTEGER_LITERAL_OUT_OF_RANGE]);
  }

  test_invalidAnnotation_importWithPrefix_notConstantVariable() async {
    newFile("/lib.dart", content: r'''
library lib;
final V = 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() async {
    newFile("/lib.dart", content: r'''
library lib;
typedef V();
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_notConstantVariable() async {
    await assertErrorsInCode(r'''
final V = 0;
@V
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_notVariableOrConstructorInvocation() async {
    await assertErrorsInCode(r'''
typedef V();
@V
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_staticMethodReference() async {
    await assertErrorsInCode(r'''
class A {
  static f() {}
}
@A.f
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotationFromDeferredLibrary() async {
    // See test_invalidAnnotation_notConstantVariable
    await resolveWithErrors(<String>[
      r'''
library lib1;
class V { const V(); }
const v = const V();
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
@a.v main () {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary_constructor() async {
    // See test_invalidAnnotation_notConstantVariable
    await resolveWithErrors(<String>[
      r'''
library lib1;
class C { const C(); }
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
@a.C() main () {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    // See test_invalidAnnotation_notConstantVariable
    await resolveWithErrors(<String>[
      r'''
library lib1;
class C { const C.name(); }
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
@a.C.name() main () {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_invalidAnnotationGetter_getter() async {
    await assertErrorsInCode(r'''
get V => 0;
@V
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION_GETTER]);
  }

  test_invalidAnnotationGetter_importWithPrefix_getter() async {
    newFile("/lib.dart", content: r'''
library lib;
get V => 0;
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
@p.V
main() {
}
''', [CompileTimeErrorCode.INVALID_ANNOTATION_GETTER]);
  }

  test_invalidConstructorName_notEnclosingClassName_defined() async {
    await assertErrorsInCode(r'''
class A {
  B() : super();
}
class B {}
''', [CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
  }

  test_invalidConstructorName_notEnclosingClassName_undefined() async {
    await assertErrorsInCode(r'''
class A {
  B() : super();
}
''', [CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
  }

  test_invalidFactoryNameNotAClass_notClassName() async {
    await assertErrorsInCode(r'''
int B;
class A {
  factory B() => null;
}
''', [CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
  }

  test_invalidFactoryNameNotAClass_notEnclosingClassName() async {
    await assertErrorsInCode(r'''
class A {
  factory B() => null;
}
''', [CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
  }

  test_invalidIdentifierInAsync_async() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int async;
  }
}
''', [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
  }

  test_invalidIdentifierInAsync_await() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int await;
  }
}
''', [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
  }

  test_invalidIdentifierInAsync_yield() async {
    await assertErrorsInCode(r'''
class A {
  m() async {
    int yield;
  }
}
''', [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
  }

  test_invalidModifierOnConstructor_async() async {
    await assertErrorsInCode(r'''
class A {
  A() async {}
}
''', [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
  }

  test_invalidModifierOnConstructor_asyncStar() async {
    await assertErrorsInCode(r'''
class A {
  A() async* {}
}
''', [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
  }

  test_invalidModifierOnConstructor_syncStar() async {
    await assertErrorsInCode(r'''
class A {
  A() sync* {}
}
''', [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
  }

  test_invalidModifierOnSetter_member_async() async {
    // TODO(danrubel): Investigate why error message is duplicated when
    // using fasta parser.
    await assertErrorsInCode(r'''
class A {
  set x(v) async {}
}
''', [
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER
    ]);
  }

  test_invalidModifierOnSetter_member_asyncStar() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) async* {}
}
''', [
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER
    ]);
  }

  test_invalidModifierOnSetter_member_syncStar() async {
    await assertErrorsInCode(r'''
class A {
  set x(v) sync* {}
}
''', [
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER
    ]);
  }

  test_invalidModifierOnSetter_topLevel_async() async {
    await assertErrorsInCode('''
set x(v) async {}
''', [
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER
    ]);
  }

  test_invalidModifierOnSetter_topLevel_asyncStar() async {
    await assertErrorsInCode('''
set x(v) async* {}
''', [
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER
    ]);
  }

  test_invalidModifierOnSetter_topLevel_syncStar() async {
    await assertErrorsInCode('''
set x(v) sync* {}
''', [
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER,
      CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER
    ]);
  }

  test_invalidReferenceToThis_factoryConstructor() async {
    await assertErrorsInCode(r'''
class A {
  factory A() { return this; }
}
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_instanceVariableInitializer_inConstructor() async {
    await assertErrorsInCode(r'''
class A {
  var f;
  A() : f = this;
}
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration() async {
    await assertErrorsInCode(r'''
class A {
  var f = this;
}
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_staticMethod() async {
    await assertErrorsInCode(r'''
class A {
  static m() { return this; }
}
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_staticVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  static A f = this;
}
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_superInitializer() async {
    await assertErrorsInCode(r'''
class A {
  A(var x) {}
}
class B extends A {
  B() : super(this);
}
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_topLevelFunction() async {
    await assertErrorsInCode('''
f() { return this; }
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidReferenceToThis_variableInitializer() async {
    await assertErrorsInCode('''
int x = this;
''', [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
  }

  test_invalidTypeArgumentInConstList() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E>[];
  }
}
''', [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST]);
  }

  test_invalidTypeArgumentInConstMap() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <String, E>{};
  }
}
''', [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
  }

  test_invalidUri_export() async {
    await assertErrorsInCode('''
export 'ht:';
''', [CompileTimeErrorCode.INVALID_URI]);
  }

  test_invalidUri_import() async {
    await assertErrorsInCode('''
import 'ht:';
''', [CompileTimeErrorCode.INVALID_URI]);
  }

  test_invalidUri_part() async {
    await assertErrorsInCode(r'''
library lib;
part 'ht:';
''', [CompileTimeErrorCode.INVALID_URI]);
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
''', [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
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
''', [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
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
''', [CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE]);
  }

  test_labelUndefined_break() async {
    await assertErrorsInCode(r'''
f() {
  x: while (true) {
    break y;
  }
}
''', [CompileTimeErrorCode.LABEL_UNDEFINED, HintCode.UNUSED_LABEL],
        verify: false);
  }

  test_labelUndefined_continue() async {
    await assertErrorsInCode(r'''
f() {
  x: while (true) {
    continue y;
  }
}
''', [CompileTimeErrorCode.LABEL_UNDEFINED, HintCode.UNUSED_LABEL],
        verify: false);
  }

  test_length_of_erroneous_constant() async {
    // Attempting to compute the length of constant that couldn't be evaluated
    // (due to an error) should not crash the analyzer (see dartbug.com/23383)
    await assertErrorsInCode('''
const int i = (1 ? 'alpha' : 'beta').length;
''', [
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE,
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_CONDITION
    ]);
  }

  test_memberWithClassName_field() async {
    await assertErrorsInCode(r'''
class A {
  int A = 0;
}
''', [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_memberWithClassName_field2() async {
    await assertErrorsInCode(r'''
class A {
  int z, A, b = 0;
}
''', [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
  }

  test_memberWithClassName_getter() async {
    await assertErrorsInCode(r'''
class A {
  get A => 0;
}
''', [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
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
      [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
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
      [CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR],
    );
  }

  test_mixinDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B extends Object with a.A {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.MIXIN_DEFERRED_CLASS
    ]);
  }

  test_mixinDeferredClass_classTypeAlias() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B {}
class C = B with a.A;
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.MIXIN_DEFERRED_CLASS
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
''', [CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE]);
  }

  test_mixinInference_noMatchingClass_new_syntax() async {
    await assertErrorsInCode('''
abstract class A<T> {}
class B {}
mixin M<T> on A<T> {}
class C extends Object with M {}
''', [CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE]);
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
''', [CompileTimeErrorCode.MIXIN_APPLICATION_NOT_IMPLEMENTED_INTERFACE]);
  }

  test_mixinInference_recursiveSubtypeCheck_new_syntax() async {
    // See dartbug.com/32353 for a detailed explanation.
    Source source = addSource('''
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
    var analysisResult = await computeAnalysisResult(source);
    assertNoErrors(source);
    var mixins =
        analysisResult.unit.declaredElement.getType('_LocalDirectory').mixins;
    expect(mixins[0].toString(), 'ForwardingDirectory<_LocalDirectory>');
  }

  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C extends Object with B {}
''', [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}
''', [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
  }

  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {}
class C = Object with B;
''', [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
  }

  test_mixinInheritsFromNotObject_typeAlias_with() async {
    await assertErrorsInCode(r'''
class A {}
class B extends Object with A {}
class C = Object with B;
''', [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
  }

  test_mixinOfDisallowedClass_class_bool() async {
    await assertErrorsInCode('''
class A extends Object with bool {}
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_class_double() async {
    await assertErrorsInCode('''
class A extends Object with double {}
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_class_int() async {
    await assertErrorsInCode('''
class A extends Object with int {}
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_class_Null() async {
    await assertErrorsInCode('''
class A extends Object with Null {}
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_class_num() async {
    await assertErrorsInCode('''
class A extends Object with num {}
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_class_String() async {
    await assertErrorsInCode('''
class A extends Object with String {}
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_bool() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with bool;
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_double() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with double;
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_int() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with int;
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_Null() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with Null;
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_num() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with num;
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_String() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with String;
''', [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_String_num() async {
    await assertErrorsInCode(r'''
class A {}
class C = A with String, num;
''', [
      CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
      CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS
    ]);
  }

  test_mixinOfNonClass() async {
    // TODO(brianwilkerson) Compare with MIXIN_WITH_NON_CLASS_SUPERCLASS.
    await assertErrorsInCode(r'''
var A;
class B extends Object mixin A {}
''', [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
  }

  test_mixinOfNonClass_class() async {
    await assertErrorsInCode(r'''
int A;
class B extends Object with A {}
''', [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
  }

  test_mixinOfNonClass_enum() async {
    await assertErrorsInCode(r'''
enum E { ONE }
class A extends Object with E {}
''', [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
  }

  test_mixinOfNonClass_typeAlias() async {
    await assertErrorsInCode(r'''
class A {}
int B;
class C = A with B;
''', [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
  }

  test_mixinReferencesSuper() async {
    await assertErrorsInCode(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}
''', [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
  }

  test_mixinWithNonClassSuperclass_class() async {
    await assertErrorsInCode(r'''
int A;
class B {}
class C extends A with B {}
''', [CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
  }

  test_mixinWithNonClassSuperclass_typeAlias() async {
    await assertErrorsInCode(r'''
int A;
class B {}
class C = A with B;
''', [CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
  }

  test_multipleRedirectingConstructorInvocations() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}
''', [CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS]);
  }

  test_multipleSuperInitializers() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  B() : super(), super() {}
}
''', [
      CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS,
      StrongModeCode.INVALID_SUPER_INVOCATION
    ]);
  }

  test_nativeClauseInNonSDKCode() async {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    await assertErrorsInCode('''
class A native 'string' {}
''', [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
  }

  test_nativeFunctionBodyInNonSDKCode_function() async {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    await assertErrorsInCode('''
int m(a) native 'string';
''', [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
  }

  test_nativeFunctionBodyInNonSDKCode_method() async {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    await assertErrorsInCode(r'''
class A{
  static int m(a) native 'string';
}
''', [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
  }

  test_noAnnotationConstructorArguments() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
@A
main() {
}
''', [CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS]);
  }

  test_noDefaultSuperConstructorExplicit() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
  B() {}
}
''', [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
  }

  test_noDefaultSuperConstructorImplicit_superHasParameters() async {
    await assertErrorsInCode(r'''
class A {
  A(p);
}
class B extends A {
}
''', [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
  }

  test_noDefaultSuperConstructorImplicit_superOnlyNamed() async {
    await assertErrorsInCode(r'''
class A { A.named() {} }
class B extends A {}
''', [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
  }

  test_nonConstantAnnotationConstructor_named() async {
    await assertErrorsInCode(r'''
class A {
  A.fromInt() {}
}
@A.fromInt()
main() {
}
''', [CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR]);
  }

  test_nonConstantAnnotationConstructor_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  A() {}
}
@A()
main() {
}
''', [CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR]);
  }

  test_nonConstantDefaultValue_function_named() async {
    await assertErrorsInCode(r'''
int y;
f({x : y}) {}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
  }

  test_nonConstantDefaultValue_function_positional() async {
    await assertErrorsInCode(r'''
int y;
f([x = y]) {}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
  }

  test_nonConstantDefaultValue_inConstructor_named() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  A({x : y}) {}
}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
  }

  test_nonConstantDefaultValue_inConstructor_positional() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  A([x = y]) {}
}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
  }

  test_nonConstantDefaultValue_method_named() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  m({x : y}) {}
}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
  }

  test_nonConstantDefaultValue_method_positional() async {
    await assertErrorsInCode(r'''
class A {
  int y;
  m([x = y]) {}
}
''', [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
  }

  test_nonConstantDefaultValueFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V}) {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V + 1}) {}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY
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
''', [CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION]);
  }

  test_nonConstCaseExpressionFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c:
      break;
  }
}
'''
    ], [
      CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstCaseExpressionFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c + 1:
      break;
  }
}
'''
    ], [
      CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstMapAsExpressionStatement_begin() async {
    // TODO(danrubel): Consider improving recovery
    await assertErrorsInCode(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}
''', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
    ]);
  }

  test_nonConstMapAsExpressionStatement_only() async {
    // TODO(danrubel): Consider improving recovery
    await assertErrorsInCode(r'''
f() {
  {'a' : 0, 'b' : 1};
}
''', [
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
    ]);
  }

  test_nonConstValueInInitializer_assert_condition() async {
    await assertErrorsInCode(r'''
class A {
  const A(int i) : assert(i.isNegative);
}
''', [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_nonConstValueInInitializer_assert_message() async {
    await assertErrorsInCode(r'''
class A {
  const A(int i) : assert(i < 0, 'isNegative = ${i.isNegative}');
}
''', [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_nonConstValueInInitializer_field() async {
    await assertErrorsInCode(r'''
class A {
  static int C;
  final int a;
  const A() : a = C;
}
''', [CompileTimeErrorCode.INVALID_CONSTANT]);
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
      CompileTimeErrorCode.INVALID_CONSTANT,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION
    ]);
  }

  test_nonConstValueInInitializer_instanceCreation_inDifferentFile() async {
    Source sourceA = addNamedSource('/a.dart', r'''
import 'b.dart';
const v = const MyClass();
''');
    Source sourceB = addNamedSource('/b.dart', r'''
class MyClass {
  const MyClass([p = foo]);
}
''');
    await computeAnalysisResult(sourceA);
    assertNoErrors(sourceA);
    await computeAnalysisResult(sourceB);
    assertErrors(sourceB, [
      CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE,
      StaticWarningCode.UNDEFINED_IDENTIFIER
    ]);
  }

  test_nonConstValueInInitializer_redirecting() async {
    await assertErrorsInCode(r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
}
''', [CompileTimeErrorCode.INVALID_CONSTANT]);
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
''', [CompileTimeErrorCode.INVALID_CONSTANT]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_field() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c;
}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_CONSTANT
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_field_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_CONSTANT
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_CONSTANT
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_super() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;
''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
}
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_CONSTANT
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
''', [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
  }

  test_nonGenerativeConstructor_implicit() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends A {
  B();
}
''', [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
  }

  test_nonGenerativeConstructor_implicit2() async {
    await assertErrorsInCode(r'''
class A {
  factory A() => null;
}
class B extends A {
}
''', [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
  }

  test_notEnoughRequiredArguments_const() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
main() {
  const A();
}
''', [CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
  }

  test_notEnoughRequiredArguments_const_super() async {
    await assertErrorsInCode(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}
''', [CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
  }

  test_objectCannotExtendAnotherClass() async {
    await assertErrorsInCode(r'''
class Object extends List {}
''', [CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS]);
  }

  test_optionalParameterInOperator_named() async {
    await assertErrorsInCode(r'''
class A {
  operator +({p}) {}
}
''', [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
  }

  test_optionalParameterInOperator_positional() async {
    await assertErrorsInCode(r'''
class A {
  operator +([p]) {}
}
''', [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
  }

  test_partOfNonPart() async {
    newFile("/l2.dart", content: '''
library l2;
''');
    await assertErrorsInCode(r'''
library l1;
part 'l2.dart';
''', [CompileTimeErrorCode.PART_OF_NON_PART]);
  }

  test_partOfNonPart_self() async {
    await assertErrorsInCode(r'''
library lib;
part 'test.dart';
''', [CompileTimeErrorCode.PART_OF_NON_PART]);
  }

  test_prefix_assignment_compound_in_method() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p += 1;
  }
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_assignment_compound_not_in_method() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_assignment_in_method() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
class C {
  f() {
    p = 1;
  }
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_assignment_not_in_method() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p = 1;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_conditionalPropertyAccess_call_loadLibrary() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary();
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_conditionalPropertyAccess_get() async {
    newFile('/lib.dart', content: '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p?.x;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_conditionalPropertyAccess_get_loadLibrary() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  return p?.loadLibrary;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_conditionalPropertyAccess_set() async {
    newFile('/lib.dart', content: '''
library lib;
var x;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.x = null;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefix_conditionalPropertyAccess_set_loadLibrary() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary = null;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefixCollidesWithTopLevelMembers_functionTypeAlias() async {
    newFile("/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
typedef p();
p.A a;
''', [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
  }

  test_prefixCollidesWithTopLevelMembers_topLevelFunction() async {
    newFile("/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
p() {}
p.A a;
''', [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
  }

  test_prefixCollidesWithTopLevelMembers_topLevelVariable() async {
    newFile("/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
var p = null;
p.A a;
''', [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
  }

  test_prefixCollidesWithTopLevelMembers_type() async {
    newFile("/lib.dart", content: r'''
library lib;
class A{}
''');
    await assertErrorsInCode(r'''
import 'lib.dart' as p;
class p {}
p.A a;
''', [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
  }

  test_prefixNotFollowedByDot() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  return p;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefixNotFollowedByDot_compoundAssignment() async {
    newFile('/lib.dart', content: '''
library lib;
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_prefixNotFollowedByDot_conditionalMethodInvocation() async {
    newFile('/lib.dart', content: '''
library lib;
g() {}
''');
    await assertErrorsInCode('''
import 'lib.dart' as p;
f() {
  p?.g();
}
''', [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
  }

  test_privateCollisionInClassTypeAlias_mixinAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = Object with A, B;
''');
  }

  test_privateCollisionInClassTypeAlias_mixinAndMixin_indirect() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = Object with A;
class D = C with B;
''');
  }

  test_privateCollisionInClassTypeAlias_superclassAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = A with B;
''');
  }

  test_privateCollisionInClassTypeAlias_superclassAndMixin_same() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C = A with A;
''');
  }

  test_privateCollisionInMixinApplication_mixinAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends Object with A, B {}
''');
  }

  test_privateCollisionInMixinApplication_mixinAndMixin_indirect() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends Object with A {}
class D extends C with B {}
''');
  }

  test_privateCollisionInMixinApplication_superclassAndMixin() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends A with B {}
''');
  }

  test_privateCollisionInMixinApplication_superclassAndMixin_same() {
    return _privateCollisionInMixinApplicationTest('''
import 'lib1.dart';
class C extends A with A {}
''');
  }

  test_privateOptionalParameter() async {
    await assertErrorsInCode('''
f({var _p}) {}
''', [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
  }

  test_privateOptionalParameter_fieldFormal() async {
    await assertErrorsInCode(r'''
class A {
  var _p;
  A({this._p: 0});
}
''', [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
  }

  test_privateOptionalParameter_withDefaultValue() async {
    await assertErrorsInCode('''
f({_p : 0}) {}
''', [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
  }

  test_recursiveCompileTimeConstant() async {
    await assertErrorsInCode(r'''
class A {
  const A();
  final m = const A();
}
''', [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
  }

  test_recursiveCompileTimeConstant_cycle() async {
    await assertErrorsInCode(r'''
const x = y + 1;
const y = x + 1;
''', [
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      StrongModeCode.TOP_LEVEL_CYCLE,
      StrongModeCode.TOP_LEVEL_CYCLE,
    ]);
  }

  test_recursiveCompileTimeConstant_fromMapLiteral() async {
    newFile(
      '/constants.dart',
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
''', [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
  }

  test_recursiveCompileTimeConstant_singleVariable() async {
    await assertErrorsInCode(r'''
const x = x;
''', [
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      StrongModeCode.TOP_LEVEL_CYCLE
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
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      StrongModeCode.TOP_LEVEL_CYCLE,
    ]);
  }

  test_recursiveConstructorRedirect() async {
    await assertErrorsInCode(r'''
class A {
  A.a() : this.b();
  A.b() : this.a();
}
''', [
      CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT
    ]);
  }

  test_recursiveConstructorRedirect_directSelfReference() async {
    await assertErrorsInCode(r'''
class A {
  A() : this();
}
''', [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT]);
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
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_recursiveFactoryRedirect_directSelfReference() async {
    await assertErrorsInCode(r'''
class A {
  factory A() = A;
}
''', [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
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
''', [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
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
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
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
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
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
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
  }

  test_redirectGenerativeToMissingConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.noSuchConstructor();
}
''', [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR],
        verify: false);
  }

  test_redirectGenerativeToNonGenerativeConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A() : this.x();
  factory A.x() => null;
}
''', [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR]);
  }

  test_redirectToMissingConstructor_named() async {
    await assertErrorsInCode(r'''
class A implements B{
  A() {}
}
class B {
  const factory B() = A.name;
}
''', [CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR], verify: false);
  }

  test_redirectToMissingConstructor_unnamed() async {
    await assertErrorsInCode(r'''
class A implements B{
  A.name() {}
}
class B {
  const factory B() = A;
}
''', [CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  test_redirectToNonClass_notAType() async {
    await assertErrorsInCode(r'''
int A;
class B {
  const factory B() = A;
}
''', [CompileTimeErrorCode.REDIRECT_TO_NON_CLASS]);
  }

  test_redirectToNonClass_undefinedIdentifier() async {
    await assertErrorsInCode(r'''
class B {
  const factory B() = A;
}
''', [CompileTimeErrorCode.REDIRECT_TO_NON_CLASS]);
  }

  test_redirectToNonConstConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A.a() {}
  const factory A.b() = A.a;
}
''', [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR]);
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
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_hideInBlock_local() async {
    await assertErrorsInCode(r'''
var v = 1;
main() {
  print(v);
  var v = 2;
}
print(x) {}
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
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
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_inInitializer_closure() async {
    await assertErrorsInCode(r'''
main() {
  var v = () => v;
}
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_inInitializer_directly() async {
    await assertErrorsInCode(r'''
main() {
  var v = v;
}
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_type_localFunction() async {
    await assertErrorsInCode(r'''
void testTypeRef() {
  String s = '';
  int String(int x) => x + 1;
}
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_type_localVariable() async {
    await assertErrorsInCode(r'''
void testTypeRef() {
  String s = '';
  var String = '';
}
''', [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_rethrowOutsideCatch() async {
    await assertErrorsInCode(r'''
f() {
  rethrow;
}
''', [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH]);
  }

  test_returnInGenerativeConstructor() async {
    await assertErrorsInCode(r'''
class A {
  A() { return 0; }
}
''', [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
  }

  test_returnInGenerativeConstructor_expressionFunctionBody() async {
    await assertErrorsInCode(r'''
class A {
  A() => null;
}
''', [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
  }

  test_returnInGenerator_asyncStar() async {
    await assertErrorsInCode(r'''
f() async* {
  return 0;
}
''', [
      CompileTimeErrorCode.RETURN_IN_GENERATOR,
      CompileTimeErrorCode.RETURN_IN_GENERATOR
    ]);
  }

  test_returnInGenerator_syncStar() async {
    await assertErrorsInCode(r'''
f() sync* {
  return 0;
}
''', [
      CompileTimeErrorCode.RETURN_IN_GENERATOR,
      CompileTimeErrorCode.RETURN_IN_GENERATOR
    ]);
  }

  test_sharedDeferredPrefix() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
f1() {}
''',
      r'''
library lib2;
f2() {}
''',
      r'''
library root;
import 'lib1.dart' deferred as lib;
import 'lib2.dart' as lib;
main() { lib.f1(); lib.f2(); }
'''
    ], <ErrorCode>[
      CompileTimeErrorCode.SHARED_DEFERRED_PREFIX
    ]);
  }

  test_superInInvalidContext_binaryExpression() async {
    await assertErrorsInCode('''
var v = super + 0;
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
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
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT], verify: false);
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
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT], verify: false);
  }

  test_superInInvalidContext_instanceVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  var a;
}
class B extends A {
 var b = super.a;
}
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }

  test_superInInvalidContext_staticMethod() async {
    await assertErrorsInCode(r'''
class A {
  static m() {}
}
class B extends A {
  static n() { return super.m(); }
}
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT], verify: false);
  }

  test_superInInvalidContext_staticVariableInitializer() async {
    await assertErrorsInCode(r'''
class A {
  static int a = 0;
}
class B extends A {
  static int b = super.a;
}
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }

  test_superInInvalidContext_topLevelFunction() async {
    await assertErrorsInCode(r'''
f() {
  super.f();
}
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }

  test_superInInvalidContext_topLevelVariableInitializer() async {
    await assertErrorsInCode('''
var v = super.y;
''', [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
  }

  test_superInitializerInObject() async {
    await assertErrorsInCode(r'''
class Object {
  Object() : super();
}
''', [CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT]);
  }

  test_superInRedirectingConstructor_redirectionSuper() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B() : this.name(), super();
  B.name() {}
}
''', [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
  }

  test_superInRedirectingConstructor_superRedirection() async {
    await assertErrorsInCode(r'''
class A {}
class B {
  B() : super(), this.name();
  B.name() {}
}
''', [
      CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR,
      StrongModeCode.INVALID_SUPER_INVOCATION
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
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS,
      CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS,
      CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER
    ]);
  }

  test_test_fieldInitializerOutsideConstructor_topLevelFunction() async {
    await assertErrorsInCode(r'''
f(this.x(y)) {}
''', [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
  }

  test_typeAliasCannotReferenceItself_11987() async {
    await assertErrorsInCode(r'''
typedef void F(List<G> l);
typedef void G(List<F> l);
main() {
  F foo(G g) => g;
}
''', [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
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
''', [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
  }

  test_typeAliasCannotReferenceItself_generic() async {
    await assertErrorsInCode(r'''
typedef F = void Function(List<G> l);
typedef G = void Function(List<F> l);
main() {
  F foo(G g) => g;
}
''', [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
    ]);
  }

  test_typeAliasCannotReferenceItself_parameterType_named() async {
    await assertErrorsInCode('''
typedef A({A a});
''', [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
  }

  test_typeAliasCannotReferenceItself_parameterType_positional() async {
    await assertErrorsInCode('''
typedef A([A a]);
''', [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
  }

  test_typeAliasCannotReferenceItself_parameterType_required() async {
    await assertErrorsInCode('''
typedef A(A a);
''', [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
  }

  test_typeAliasCannotReferenceItself_parameterType_typeArgument() async {
    await assertErrorsInCode('''
typedef A(List<A> a);
''', [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
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
''', [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
  }

  test_typeAliasCannotReferenceItself_returnType_indirect() async {
    await assertErrorsInCode(r'''
typedef B A();
typedef A B();
''', [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
    ]);
  }

  test_typeAliasCannotReferenceItself_typeVariableBounds() async {
    await assertErrorsInCode('''
typedef A<T extends A<int>>();
''', [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      StaticTypeWarningCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
    ]);
  }

  test_typeArgumentNotMatchingBounds_const() async {
    await assertErrorsInCode(r'''
class A {}
class B {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }
''', [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
  }

  test_typedef_infiniteParameterBoundCycle() async {
    await assertErrorsInCode(r'''
typedef F<X extends F> = F Function();
''', [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      StrongModeCode.NOT_INSTANTIATED_BOUND,
    ]);
  }

  test_undefinedAnnotation_unresolved_identifier() async {
    await assertErrorsInCode(r'''
@unresolved
main() {
}
''', [CompileTimeErrorCode.UNDEFINED_ANNOTATION]);
  }

  test_undefinedAnnotation_unresolved_invocation() async {
    await assertErrorsInCode(r'''
@Unresolved()
main() {
}
''', [CompileTimeErrorCode.UNDEFINED_ANNOTATION]);
  }

  test_undefinedAnnotation_unresolved_prefixedIdentifier() async {
    await assertErrorsInCode(r'''
import 'dart:math' as p;
@p.unresolved
main() {
}
''', [CompileTimeErrorCode.UNDEFINED_ANNOTATION]);
  }

  test_undefinedAnnotation_useLibraryScope() async {
    await assertErrorsInCode(r'''
@foo
class A {
  static const foo = null;
}
''', [CompileTimeErrorCode.UNDEFINED_ANNOTATION]);
  }

  test_undefinedClass_const() async {
    await assertErrorsInCode(r'''
f() {
  return const A();
}
''', [StaticWarningCode.UNDEFINED_CLASS]);
  }

  test_undefinedConstructorInInitializer_explicit_named() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  B() : super.named();
}
''', [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER],
        verify: false);
  }

  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
}
''', [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
  }

  test_undefinedConstructorInInitializer_implicit() async {
    await assertErrorsInCode(r'''
class A {
  A.named() {}
}
class B extends A {
  B();
}
''', [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
  }

  test_undefinedNamedParameter() async {
    await assertErrorsInCode(r'''
class A {
  const A();
}
main() {
  const A(p: 0);
}
''', [CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER]);
  }

  test_uriDoesNotExist_export() async {
    await assertErrorsInCode('''
export 'unknown.dart';
''', [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriDoesNotExist_import() async {
    await assertErrorsInCode('''
import 'unknown.dart';
''', [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriDoesNotExist_import_appears_after_deleting_target() async {
    Source target = addNamedSource("/target.dart", '''
''');
    Source test = addSource('''
import 'target.dart';
''');
    await computeAnalysisResult(test);
    assertErrors(test, [HintCode.UNUSED_IMPORT]);

    // Remove the overlay in the same way as AnalysisServer.
    deleteFile(target.fullName);
    driver.removeFile(target.fullName);

    await computeAnalysisResult(test);
    assertErrors(test, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriDoesNotExist_import_disappears_when_fixed() async {
    Source source = addSource('''
import 'target.dart';
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);

    String targetPath = convertPath('/target.dart');
    // Add an overlay in the same way as AnalysisServer.
    fileContentOverlay[targetPath] = '';
    driver.changeFile(targetPath);

    // Make sure the error goes away.
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
  }

  test_uriDoesNotExist_part() async {
    await assertErrorsInCode(r'''
library lib;
part 'unknown.dart';
''', [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriWithInterpolation_constant() async {
    await assertErrorsInCode('''
import 'stuff_\$platform.dart';
''', [
      CompileTimeErrorCode.URI_WITH_INTERPOLATION,
      StaticWarningCode.UNDEFINED_IDENTIFIER
    ]);
  }

  test_uriWithInterpolation_nonConstant() async {
    await assertErrorsInCode(r'''
library lib;
part '${'a'}.dart';
''', [CompileTimeErrorCode.URI_WITH_INTERPOLATION]);
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
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS]);
  }

  test_wrongNumberOfParametersForOperator_tilde() async {
    await _check_wrongNumberOfParametersForOperator('~', 'a');
    await _check_wrongNumberOfParametersForOperator('~', 'a, b');
  }

  test_wrongNumberOfParametersForSetter_function_named() async {
    await assertErrorsInCode('''
set x({p}) {}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_function_optional() async {
    await assertErrorsInCode('''
set x([p]) {}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_function_tooFew() async {
    await assertErrorsInCode('''
set x() {}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_function_tooMany() async {
    await assertErrorsInCode('''
set x(a, b) {}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_method_named() async {
    await assertErrorsInCode(r'''
class A {
  set x({p}) {}
}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_method_optional() async {
    await assertErrorsInCode(r'''
class A {
  set x([p]) {}
}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_method_tooFew() async {
    await assertErrorsInCode(r'''
class A {
  set x() {}
}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_wrongNumberOfParametersForSetter_method_tooMany() async {
    await assertErrorsInCode(r'''
class A {
  set x(a, b) {}
}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
  }

  test_yield_used_as_identifier_in_async_method() async {
    await assertErrorsInCode('''
f() async {
  var yield = 1;
}
''', [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
  }

  test_yield_used_as_identifier_in_async_star_method() async {
    await assertErrorsInCode('''
f() async* {
  var yield = 1;
}
''', [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
  }

  test_yield_used_as_identifier_in_sync_star_method() async {
    await assertErrorsInCode('''
f() sync* {
  var yield = 1;
}
''', [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
  }

  test_yieldEachInNonGenerator_async() async {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    await assertErrorsInCode(r'''
f() async {
  yield* 0;
}
''', [CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR]);
  }

  test_yieldEachInNonGenerator_sync() async {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    await assertErrorsInCode(r'''
f() {
  yield* 0;
}
''', [CompileTimeErrorCode.YIELD_IN_NON_GENERATOR]);
  }

  test_yieldInNonGenerator_async() async {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    await assertErrorsInCode(r'''
f() async {
  yield 0;
}
''', [CompileTimeErrorCode.YIELD_IN_NON_GENERATOR]);
  }

  test_yieldInNonGenerator_sync() async {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    await assertErrorsInCode(r'''
f() {
  yield 0;
}
''', [CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR]);
  }

  Future<void> _check_constEvalThrowsException_binary_null(
      String expr, bool resolved) async {
    await assertErrorsInCode('''
const C = $expr;
''', [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION], verify: false);
  }

  Future<void> _check_constEvalTypeBoolOrInt_binary(String expr) async {
    await assertErrorsInCode('''
const int a = 0;
const _ = $expr;
''', [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_INT,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  Future<void> _check_constEvalTypeInt_binary(String expr) async {
    await assertErrorsInCode('''
const int a = 0;
const _ = $expr;
''', [
      CompileTimeErrorCode.CONST_EVAL_TYPE_INT,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  Future<void> _check_constEvalTypeNum_binary(String expr) async {
    await assertErrorsInCode('''
const num a = 0;
const _ = $expr;
''', [
      CompileTimeErrorCode.CONST_EVAL_TYPE_NUM,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  Future<void> _check_wrongNumberOfParametersForOperator(
      String name, String parameters) async {
    await assertErrorsInCode('''
class A {
  operator $name($parameters) {}
}
''', [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR]);
  }

  Future<void> _check_wrongNumberOfParametersForOperator1(String name) async {
    await _check_wrongNumberOfParametersForOperator(name, '');
    await _check_wrongNumberOfParametersForOperator(name, 'a, b');
  }

  Future<void> _privateCollisionInMixinApplicationTest(String testCode) async {
    newFile('/lib1.dart', content: '''
class A {
  int _x;
}

class B {
  int _x;
}
''');
    await assertErrorsInCode(testCode,
        [CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION]);
  }
}
