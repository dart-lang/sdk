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

class CompileTimeErrorCodeTestBase extends DriverResolutionTest {
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
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 61, 1),
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
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 49, 1),
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER, 49, 1),
    ]);
  }

  test_constConstructorWithNonFinalField_this_named() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  const A.a();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 27, 3),
    ]);
  }

  test_constConstructorWithNonFinalField_this_unnamed() async {
    await assertErrorsInCode(r'''
class A {
  int x;
  const A();
}
''', [
      error(CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD, 27, 1),
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

  test_constEvalThrowsException_divisionByZero() async {
    await assertErrorsInCode('''
const C = 1 ~/ 0;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE, 10, 6),
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

  test_constWithNonConst() async {
    await assertErrorsInCode(r'''
class T {
  T(a, b, {c, d}) {}
}
f() { return const T(0, 1, c: 2, d: 3); }
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 46, 5),
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

  test_constWithNonConst_mixinApplication_constSuperConstructor() async {
    await assertNoErrorsInCode(r'''
mixin M {}
class A {
  const A();
}
class B = A with M;
const b = const B();
''');
  }

  test_constWithNonConst_mixinApplication_constSuperConstructor_field() async {
    await assertErrorsInCode(r'''
mixin M {
  int i = 0;
}
class A {
  const A();
}
class B = A with M;
var b = const B();
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 78, 5),
    ]);
  }

  test_constWithNonConst_mixinApplication_constSuperConstructor_getter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  int get i => 0;
}
class A {
  const A();
}
class B = A with M;
var b = const B();
''');
  }

  test_constWithNonConst_mixinApplication_constSuperConstructor_setter() async {
    await assertNoErrorsInCode(r'''
mixin M {
  set(int i) {}
}
class A {
  const A();
}
class B = A with M;
var b = const B();
''');
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

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/38352')
  test_constWithNonConstantArgument_classShadowedBySetter() async {
    // TODO(paulberry): once this is fixed, change this test to use
    // assertErrorsInCode and verify the exact error message(s).
    var code = '''
class Annotation {
  const Annotation(Object obj);
}

class Bar {}

class Foo {
  @Annotation(Bar)
  set Bar(int value) {}
}
''';
    addTestFile(code);
    await resolveTestFile();
    assertHasTestErrors();
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
    driver.declaredVariables = DeclaredVariables.fromMap({'x': 'true'});
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
}
