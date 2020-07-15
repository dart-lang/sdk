// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/declared_variables.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';

class CompileTimeErrorCodeTestBase extends DriverResolutionTest {
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
