// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.compile_time_error_code_test;

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:unittest/unittest.dart' as _ut;

import '../reflective_tests.dart';
import 'resolver_test.dart';


main() {
  _ut.groupSep = ' | ';
  runReflectiveTests(CompileTimeErrorCodeTest);
}

class CompileTimeErrorCodeTest extends ResolverTestCase {
  void fail_compileTimeConstantRaisesException() {
    Source source = addSource(r'''
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.COMPILE_TIME_CONSTANT_RAISES_EXCEPTION]);
    verify([source]);
  }

  void fail_constEvalThrowsException() {
    Source source = addSource(r'''
class C {
  const C();
}
f() { return const C(); }''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION]);
    verify([source]);
  }

  void fail_invalidIdentifierInAsync_async() {
    // TODO(brianwilkerson) Report this error.
    resetWithAsync();
    Source source = addSource(r'''
class A {
  m() async {
    int async;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC]);
    verify([source]);
  }

  void fail_invalidIdentifierInAsync_await() {
    // TODO(brianwilkerson) Report this error.
    resetWithAsync();
    Source source = addSource(r'''
class A {
  m() async {
    int await;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC]);
    verify([source]);
  }

  void fail_invalidIdentifierInAsync_yield() {
    // TODO(brianwilkerson) Report this error.
    resetWithAsync();
    Source source = addSource(r'''
class A {
  m() async {
    int yield;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC]);
    verify([source]);
  }

  void fail_mixinDeclaresConstructor() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends Object mixin A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  void fail_mixinOfNonClass() {
    // TODO(brianwilkerson) Compare with MIXIN_WITH_NON_CLASS_SUPERCLASS.
    Source source = addSource(r'''
var A;
class B extends Object mixin A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }

  void fail_objectCannotExtendAnotherClass() {
    Source source = addSource(r'''
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS]);
    verify([source]);
  }

  void fail_recursiveCompileTimeConstant() {
    Source source = addSource(r'''
class A {
  const A();
  final m = const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }

  void fail_recursiveCompileTimeConstant_cycle() {
    Source source = addSource(r'''
const x = y + 1;
const y = x + 1;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }

  void fail_superInitializerInObject() {
    Source source = addSource(r'''
''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT]);
    verify([source]);
  }

  void fail_yieldEachInNonGenerator_async() {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    resetWithAsync();
    Source source = addSource(r'''
f() async {
  yield* 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR]);
    verify([source]);
  }

  void fail_yieldEachInNonGenerator_sync() {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    resetWithAsync();
    Source source = addSource(r'''
f() {
  yield* 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_IN_NON_GENERATOR]);
    verify([source]);
  }

  void fail_yieldInNonGenerator_async() {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    resetWithAsync();
    Source source = addSource(r'''
f() async {
  yield 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_IN_NON_GENERATOR]);
    verify([source]);
  }

  void fail_yieldInNonGenerator_sync() {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    resetWithAsync();
    Source source = addSource(r'''
f() {
  yield 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR]);
    verify([source]);
  }

  void test_accessPrivateEnumField() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE }
String name(E e) {
  return e._name;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD]);
    // Cannot verify because "_name" cannot be resolved.
  }

  void test_ambiguousExport() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';
export 'lib2.dart';''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class N {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class N {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.AMBIGUOUS_EXPORT]);
    verify([source]);
  }

  void test_asyncForInWrongContext() {
    Source source = addSource(r'''
f(list) {
  await for (var e in list) {
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT]);
    verify([source]);
  }

  void test_awaitInWrongContext_sync() {
    resetWithAsync();
    Source source = addSource(r'''
f(x) {
  return await x;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT]);
    verify([source]);
  }

  void test_awaitInWrongContext_syncStar() {
    resetWithAsync();
    Source source = addSource(r'''
f(x) sync* {
  yield await x;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT]);
    verify([source]);
  }

  void test_builtInIdentifierAsMixinName_classTypeAlias() {
    Source source = addSource(r'''
class A {}
class B {}
class as = A with B;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }

  void test_builtInIdentifierAsType_formalParameter_field() {
    Source source = addSource(r'''
class A {
  var x;
  A(static this.x);
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    verify([source]);
  }

  void test_builtInIdentifierAsType_formalParameter_simple() {
    Source source = addSource(r'''
f(static x) {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    verify([source]);
  }

  void test_builtInIdentifierAsType_variableDeclaration() {
    Source source = addSource(r'''
f() {
  typedef x;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    verify([source]);
  }

  void test_builtInIdentifierAsTypedefName_functionTypeAlias() {
    Source source = addSource("typedef bool as();");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }

  void test_builtInIdentifierAsTypeName() {
    Source source = addSource("class as {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME]);
    verify([source]);
  }

  void test_builtInIdentifierAsTypeParameterName() {
    Source source = addSource("class A<as> {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME]);
    verify([source]);
  }

  void test_caseExpressionTypeImplementsEquals() {
    Source source = addSource(r'''
class IntWrapper {
  final int value;
  const IntWrapper(this.value);
  bool operator ==(IntWrapper x) {
    return value == x.value;
  }
  get hashCode => value;
}

f(var a) {
  switch(a) {
    case(const IntWrapper(1)) : return 1;
    default: return 0;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_conflictingConstructorNameAndMember_field() {
    Source source = addSource(r'''
class A {
  int x;
  A.x() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD]);
    verify([source]);
  }

  void test_conflictingConstructorNameAndMember_method() {
    Source source = addSource(r'''
class A {
  const A.x();
  void x() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD]);
    verify([source]);
  }

  void test_conflictingGetterAndMethod_field_method() {
    Source source = addSource(r'''
class A {
  final int m = 0;
}
class B extends A {
  m() {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD]);
    verify([source]);
  }

  void test_conflictingGetterAndMethod_getter_method() {
    Source source = addSource(r'''
class A {
  get m => 0;
}
class B extends A {
  m() {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD]);
    verify([source]);
  }

  void test_conflictingGetterAndMethod_method_field() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  int m;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER]);
    verify([source]);
  }

  void test_conflictingGetterAndMethod_method_getter() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  get m => 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER]);
    verify([source]);
  }

  void test_conflictingTypeVariableAndClass() {
    Source source = addSource(r'''
class T<T> {
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS]);
    verify([source]);
  }

  void test_conflictingTypeVariableAndMember_field() {
    Source source = addSource(r'''
class A<T> {
  var T;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  void test_conflictingTypeVariableAndMember_getter() {
    Source source = addSource(r'''
class A<T> {
  get T => null;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  void test_conflictingTypeVariableAndMember_method() {
    Source source = addSource(r'''
class A<T> {
  T() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  void test_conflictingTypeVariableAndMember_method_static() {
    Source source = addSource(r'''
class A<T> {
  static T() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  void test_conflictingTypeVariableAndMember_setter() {
    Source source = addSource(r'''
class A<T> {
  set T(x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  void test_consistentCaseExpressionTypes_dynamic() {
    // Even though A.S and S have a static type of "dynamic", we should see
    // that they match 'abc', because they are constant strings.
    Source source = addSource(r'''
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
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithFieldInitializedByNonConst() {
    Source source = addSource(r'''
class A {
  final int i = f();
  const A();
}
int f() {
  return 3;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST]);
    verify([source]);
  }

  void test_constConstructorWithFieldInitializedByNonConst_static() {
    Source source = addSource(r'''
class A {
  static final int i = f();
  const A();
}
int f() {
  return 3;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constConstructorWithMixin() {
    Source source = addSource(r'''
class M {
}
class A extends Object with M {
  const A();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN]);
    verify([source]);
  }

  void test_constConstructorWithNonConstSuper_explicit() {
    Source source = addSource(r'''
class A {
  A();
}
class B extends A {
  const B(): super();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
    verify([source]);
  }

  void test_constConstructorWithNonConstSuper_implicit() {
    Source source = addSource(r'''
class A {
  A();
}
class B extends A {
  const B();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_mixin() {
    Source source = addSource(r'''
class A {
  var a;
}
class B extends Object with A {
  const B();
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN,
            CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_super() {
    Source source = addSource(r'''
class A {
  var a;
}
class B extends A {
  const B();
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
            CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
    verify([source]);
  }

  void test_constConstructorWithNonFinalField_this() {
    Source source = addSource(r'''
class A {
  int x;
  const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }

  void test_constDeferredClass() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {
  const A();
}''', r'''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A();
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.CONST_DEFERRED_CLASS]);
  }

  void test_constDeferredClass_namedConstructor() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {
  const A.b();
}''', r'''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A.b();
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.CONST_DEFERRED_CLASS]);
  }

  void test_constEval_newInstance_constConstructor() {
    Source source = addSource(r'''
class A {
  const A();
}
const a = new A();''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  void test_constEval_newInstance_externalFactoryConstConstructor() {
    // We can't evaluate "const A()" because its constructor is external.  But
    // the code is correct--we shouldn't report an error.
    Source source = addSource(r'''
class A {
  external factory const A();
}
const x = const A();''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_constEval_propertyExtraction_targetNotConst() {
    Source source = addSource(r'''
class A {
  const A();
  m() {}
}
final a = const A();
const C = a.m;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  void test_constEvalThrowsException_binaryMinus_null() {
    _check_constEvalThrowsException_binary_null("null - 5", false);
    _check_constEvalThrowsException_binary_null("5 - null", true);
  }

  void test_constEvalThrowsException_binaryPlus_null() {
    _check_constEvalThrowsException_binary_null("null + 5", false);
    _check_constEvalThrowsException_binary_null("5 + null", true);
  }

  void test_constEvalThrowsException_divisionByZero() {
    Source source = addSource("const C = 1 ~/ 0;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE]);
    verify([source]);
  }

  void test_constEvalThrowsException_unaryBitNot_null() {
    Source source = addSource("const C = ~null;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    // no verify(), '~null' is not resolved
  }

  void test_constEvalThrowsException_unaryNegated_null() {
    Source source = addSource("const C = -null;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    // no verify(), '-null' is not resolved
  }

  void test_constEvalThrowsException_unaryNot_null() {
    Source source = addSource("const C = !null;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    verify([source]);
  }

  void test_constEvalTypeBool_binary() {
    _check_constEvalTypeBool_withParameter_binary("p && ''");
    _check_constEvalTypeBool_withParameter_binary("p || ''");
  }

  void test_constEvalTypeBool_binary_leftTrue() {
    Source source = addSource("const C = (true || 0);");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
            StaticTypeWarningCode.NON_BOOL_OPERAND,
            HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_constEvalTypeBoolNumString_equal() {
    Source source = addSource(r'''
class A {
  const A();
}
class B {
  final a;
  const B(num p) : a = p == const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
    verify([source]);
  }

  void test_constEvalTypeBoolNumString_notEqual() {
    Source source = addSource(r'''
class A {
  const A();
}
class B {
  final a;
  const B(String p) : a = p != const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
    verify([source]);
  }

  void test_constEvalTypeInt_binary() {
    _check_constEvalTypeInt_withParameter_binary("p ^ ''");
    _check_constEvalTypeInt_withParameter_binary("p & ''");
    _check_constEvalTypeInt_withParameter_binary("p | ''");
    _check_constEvalTypeInt_withParameter_binary("p >> ''");
    _check_constEvalTypeInt_withParameter_binary("p << ''");
  }

  void test_constEvalTypeNum_binary() {
    _check_constEvalTypeNum_withParameter_binary("p + ''");
    _check_constEvalTypeNum_withParameter_binary("p - ''");
    _check_constEvalTypeNum_withParameter_binary("p * ''");
    _check_constEvalTypeNum_withParameter_binary("p / ''");
    _check_constEvalTypeNum_withParameter_binary("p ~/ ''");
    _check_constEvalTypeNum_withParameter_binary("p > ''");
    _check_constEvalTypeNum_withParameter_binary("p < ''");
    _check_constEvalTypeNum_withParameter_binary("p >= ''");
    _check_constEvalTypeNum_withParameter_binary("p <= ''");
    _check_constEvalTypeNum_withParameter_binary("p % ''");
  }

  void test_constFormalParameter_fieldFormalParameter() {
    Source source = addSource(r'''
class A {
  var x;
  A(const this.x) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }

  void test_constFormalParameter_simpleFormalParameter() {
    Source source = addSource("f(const x) {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }

  void test_constInitializedWithNonConstValue() {
    Source source = addSource(r'''
f(p) {
  const C = p;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  void test_constInitializedWithNonConstValue_missingConstInListLiteral() {
    Source source = addSource("const List L = [0];");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  void test_constInitializedWithNonConstValue_missingConstInMapLiteral() {
    Source source = addSource("const Map M = {'a' : 0};");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  void test_constInitializedWithNonConstValueFromDeferredClass() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const V = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V;'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY]);
  }

  void test_constInitializedWithNonConstValueFromDeferredClass_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const V = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V + 1;'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY]);
  }

  void test_constInstanceField() {
    Source source = addSource(r'''
class C {
  const int f = 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
    verify([source]);
  }

  void test_constMapKeyTypeImplementsEquals_direct() {
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
main() {
  const {const A() : 0};
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_constMapKeyTypeImplementsEquals_dynamic() {
    // Note: static type of B.a is "dynamic", but actual type of the const
    // object is A.  We need to make sure we examine the actual type when
    // deciding whether there is a problem with operator==.
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B {
  static const a = const A();
}
main() {
  const {B.a : 0};
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_constMapKeyTypeImplementsEquals_factory() {
    Source source = addSource(r'''
class A { const factory A() = B; }

class B implements A {
  const B();

  operator ==(o) => true;
}

main() {
  var m = const { const A(): 42 };
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_constMapKeyTypeImplementsEquals_super() {
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
class B extends A {
  const B();
}
main() {
  const {const B() : 0};
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  void test_constWithInvalidTypeParameters() {
    Source source = addSource(r'''
class A {
  const A();
}
f() { return const A<A>(); }''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  void test_constWithInvalidTypeParameters_tooFew() {
    Source source = addSource(r'''
class A {}
class C<K, V> {
  const C();
}
f(p) {
  return const C<A>();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  void test_constWithInvalidTypeParameters_tooMany() {
    Source source = addSource(r'''
class A {}
class C<E> {
  const C();
}
f(p) {
  return const C<A, A>();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  void test_constWithNonConst() {
    Source source = addSource(r'''
class T {
  T(a, b, {c, d}) {}
}
f() { return const T(0, 1, c: 2, d: 3); }''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_WITH_NON_CONST]);
    verify([source]);
  }

  void test_constWithNonConstantArgument_annotation() {
    Source source = addSource(r'''
class A {
  const A(int p);
}
var v = 42;
@A(v)
main() {
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT]);
    verify([source]);
  }

  void test_constWithNonConstantArgument_instanceCreation() {
    Source source = addSource(r'''
class A {
  const A(a);
}
f(p) { return const A(p); }''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT]);
    verify([source]);
  }

  void test_constWithNonType() {
    Source source = addSource(r'''
int A;
f() {
  return const A();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source]);
  }

  void test_constWithNonType_fromLibrary() {
    Source source1 = addNamedSource("lib.dart", "");
    Source source2 = addNamedSource("lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  const lib.A();
}''');
    resolve(source1);
    resolve(source2);
    assertErrors(source2, [CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source1]);
  }

  void test_constWithTypeParameters_direct() {
    Source source = addSource(r'''
class A<T> {
  static const V = const A<T>();
  const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
            StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_constWithTypeParameters_indirect() {
    Source source = addSource(r'''
class A<T> {
  static const V = const A<List<T>>();
  const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
            StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC]);
    verify([source]);
  }

  void test_constWithUndefinedConstructor() {
    Source source = addSource(r'''
class A {
  const A();
}
f() {
  return const A.noSuchConstructor();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
    // no verify(), 'noSuchConstructor' is not resolved
  }

  void test_constWithUndefinedConstructorDefault() {
    Source source = addSource(r'''
class A {
  const A.name();
}
f() {
  return const A();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }

  void test_defaultValueInFunctionTypeAlias() {
    Source source = addSource("typedef F([x = 0]);");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }

  void test_defaultValueInFunctionTypedParameter_named() {
    Source source = addSource("f(g({p: null})) {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER]);
    verify([source]);
  }

  void test_defaultValueInFunctionTypedParameter_optional() {
    Source source = addSource("f(g([p = null])) {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER]);
    verify([source]);
  }

  void test_defaultValueInRedirectingFactoryConstructor() {
    Source source = addSource(r'''
class A {
  factory A([int x = 0]) = B;
}

class B implements A {
  B([int x = 1]) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR]);
    verify([source]);
  }

  void test_duplicateConstructorName_named() {
    Source source = addSource(r'''
class A {
  A.a() {}
  A.a() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
            CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME]);
    verify([source]);
  }

  void test_duplicateConstructorName_unnamed() {
    Source source = addSource(r'''
class A {
  A() {}
  A() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
            CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }

  void test_duplicateDefinition() {
    Source source = addSource(r'''
f() {
  int m = 0;
  m(a) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  void test_duplicateDefinition_acrossLibraries() {
    Source librarySource = addNamedSource("/lib.dart", r'''
library lib;

part 'a.dart';
part 'b.dart';''');
    Source sourceA = addNamedSource("/a.dart", r'''
part of lib;

class A {}''');
    Source sourceB = addNamedSource("/b.dart", r'''
part of lib;

class A {}''');
    resolve(librarySource);
    assertErrors(sourceB, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA, sourceB]);
  }

  void test_duplicateDefinition_classMembers_fields() {
    Source source = addSource(r'''
class A {
  int a;
  int a;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  void test_duplicateDefinition_classMembers_fields_oneStatic() {
    Source source = addSource(r'''
class A {
  int x;
  static int x;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  void test_duplicateDefinition_classMembers_methods() {
    Source source = addSource(r'''
class A {
  m() {}
  m() {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  void test_duplicateDefinition_localFields() {
    Source source = addSource(r'''
class A {
  m() {
    int a;
    int a;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  void test_duplicateDefinitionInheritance_instanceGetter_staticGetter() {
    Source source = addSource(r'''
class A {
  int get x => 0;
}
class B extends A {
  static int get x => 0;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  void
      test_duplicateDefinitionInheritance_instanceGetterAbstract_staticGetter() {
    Source source = addSource(r'''
abstract class A {
  int get x;
}
class B extends A {
  static int get x => 0;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  void test_duplicateDefinitionInheritance_instanceMethod_staticMethod() {
    Source source = addSource(r'''
class A {
  x() {}
}
class B extends A {
  static x() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  void
      test_duplicateDefinitionInheritance_instanceMethodAbstract_staticMethod() {
    Source source = addSource(r'''
abstract class A {
  x();
}
abstract class B extends A {
  static x() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  void test_duplicateDefinitionInheritance_instanceSetter_staticSetter() {
    Source source = addSource(r'''
class A {
  set x(value) {}
}
class B extends A {
  static set x(value) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  void
      test_duplicateDefinitionInheritance_instanceSetterAbstract_staticSetter() {
    Source source = addSource(r'''
abstract class A {
  set x(value);
}
class B extends A {
  static set x(value) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  void test_duplicateNamedArgument() {
    Source source = addSource(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT]);
    verify([source]);
  }

  void test_exportInternalLibrary() {
    Source source = addSource("export 'dart:_interceptors';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY]);
    verify([source]);
  }

  void test_exportOfNonLibrary() {
    Source source = addSource(r'''
library L;
export 'lib1.dart';''');
    addNamedSource("/lib1.dart", "part of lib;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
    verify([source]);
  }

  void test_extendsDeferredClass() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {}''', r'''
library root;
import 'lib1.dart' deferred as a;
class B extends a.A {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS]);
  }

  void test_extendsDeferredClass_classTypeAlias() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {}''', r'''
library root;
import 'lib1.dart' deferred as a;
class M {}
class C = a.A with M;'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS]);
  }

  void test_extendsDisallowedClass_class_bool() {
    Source source = addSource("class A extends bool {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_extendsDisallowedClass_class_double() {
    Source source = addSource("class A extends double {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_extendsDisallowedClass_class_int() {
    Source source = addSource("class A extends int {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_extendsDisallowedClass_class_Null() {
    Source source = addSource("class A extends Null {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_extendsDisallowedClass_class_num() {
    Source source = addSource("class A extends num {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_extendsDisallowedClass_class_String() {
    Source source = addSource("class A extends String {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_extendsDisallowedClass_classTypeAlias_bool() {
    Source source = addSource(r'''
class M {}
class C = bool with M;''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_extendsDisallowedClass_classTypeAlias_double() {
    Source source = addSource(r'''
class M {}
class C = double with M;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_extendsDisallowedClass_classTypeAlias_int() {
    Source source = addSource(r'''
class M {}
class C = int with M;''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_extendsDisallowedClass_classTypeAlias_Null() {
    Source source = addSource(r'''
class M {}
class C = Null with M;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_extendsDisallowedClass_classTypeAlias_num() {
    Source source = addSource(r'''
class M {}
class C = num with M;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_extendsDisallowedClass_classTypeAlias_String() {
    Source source = addSource(r'''
class M {}
class C = String with M;''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
            CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_extendsEnum() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE }
class A extends E {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_ENUM]);
    verify([source]);
  }

  void test_extendsNonClass_class() {
    Source source = addSource(r'''
int A;
class B extends A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_NON_CLASS]);
    verify([source]);
  }

  void test_extendsNonClass_dynamic() {
    Source source = addSource("class B extends dynamic {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_NON_CLASS]);
    verify([source]);
  }

  void test_extraPositionalArguments_const() {
    Source source = addSource(r'''
class A {
  const A();
}
main() {
  const A(0);
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  void test_extraPositionalArguments_const_super() {
    Source source = addSource(r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  void test_fieldInitializedByMultipleInitializers() {
    Source source = addSource(r'''
class A {
  int x;
  A() : x = 0, x = 1 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }

  void test_fieldInitializedByMultipleInitializers_multipleInits() {
    Source source = addSource(r'''
class A {
  int x;
  A() : x = 0, x = 1, x = 2 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
            CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }

  void test_fieldInitializedByMultipleInitializers_multipleNames() {
    Source source = addSource(r'''
class A {
  int x;
  int y;
  A() : x = 0, x = 1, y = 0, y = 1 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
            CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }

  void test_fieldInitializedInParameterAndInitializer() {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) : x = 1 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }

  void test_fieldInitializerFactoryConstructor() {
    Source source = addSource(r'''
class A {
  int x;
  factory A(this.x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR]);
    verify([source]);
  }

  void test_fieldInitializerOutsideConstructor() {
    // TODO(brianwilkerson) Fix the duplicate error messages.
    Source source = addSource(r'''
class A {
  int x;
  m(this.x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [
            ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
            CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_fieldInitializerOutsideConstructor_defaultParameter() {
    Source source = addSource(r'''
class A {
  int x;
  m([this.x]) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_fieldInitializerRedirectingConstructor_afterRedirection() {
    Source source = addSource(r'''
class A {
  int x;
  A.named() {}
  A() : this.named(), x = 42;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  void test_fieldInitializerRedirectingConstructor_beforeRedirection() {
    Source source = addSource(r'''
class A {
  int x;
  A.named() {}
  A() : x = 42, this.named();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  void test_fieldInitializingFormalRedirectingConstructor() {
    Source source = addSource(r'''
class A {
  int x;
  A.named() {}
  A(this.x) : this.named();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  void test_finalInitializedMultipleTimes_initializers() {
    Source source = addSource(r'''
class A {
  final x;
  A() : x = 0, x = 0 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }

  /**
   * This test doesn't test the FINAL_INITIALIZED_MULTIPLE_TIMES code, but tests the
   * FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER code instead. It is provided here to show
   * coverage over all of the permutations of initializers in constructor declarations.
   *
   * Note: FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER covers a subset of
   * FINAL_INITIALIZED_MULTIPLE_TIMES, since it more specific, we use it instead of the broader code
   */
  void test_finalInitializedMultipleTimes_initializingFormal_initializer() {
    Source source = addSource(r'''
class A {
  final x;
  A(this.x) : x = 0 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }

  void test_finalInitializedMultipleTimes_initializingFormals() {
    Source source = addSource(r'''
class A {
  final x;
  A(this.x, this.x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES]);
    verify([source]);
  }

  void test_finalNotInitialized_instanceField_const_static() {
    Source source = addSource(r'''
class A {
  static const F;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_finalNotInitialized_library_const() {
    Source source = addSource("const F;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_finalNotInitialized_local_const() {
    Source source = addSource(r'''
f() {
  const int x;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
    verify([source]);
  }

  void test_fromEnvironment_bool_badArgs() {
    Source source = addSource(r'''
var b1 = const bool.fromEnvironment(1);
var b2 = const bool.fromEnvironment('x', defaultValue: 1);''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_fromEnvironment_bool_badDefault_whenDefined() {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    analysisContext2.declaredVariables.define("x", "true");
    Source source =
        addSource("var b = const bool.fromEnvironment('x', defaultValue: 1);");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_getterAndMethodWithSameName() {
    Source source = addSource(r'''
class A {
  x(y) {}
  get x => 0;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME]);
    verify([source]);
  }

  void test_implementsDeferredClass() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {}''', r'''
library root;
import 'lib1.dart' deferred as a;
class B implements a.A {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS]);
  }

  void test_implementsDeferredClass_classTypeAlias() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {}''', r'''
library root;
import 'lib1.dart' deferred as a;
class B {}
class M {}
class C = B with M implements a.A;'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS]);
  }

  void test_implementsDisallowedClass_class_bool() {
    Source source = addSource("class A implements bool {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_class_double() {
    Source source = addSource("class A implements double {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_class_int() {
    Source source = addSource("class A implements int {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_class_Null() {
    Source source = addSource("class A implements Null {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_class_num() {
    Source source = addSource("class A implements num {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_class_String() {
    Source source = addSource("class A implements String {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_class_String_num() {
    Source source = addSource("class A implements String, num {}");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
            CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_bool() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements bool;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_double() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements double;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_int() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements int;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_Null() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements Null;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_num() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements num;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_String() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements String;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDisallowedClass_classTypeAlias_String_num() {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements String, num;''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
            CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_implementsDynamic() {
    Source source = addSource("class A implements dynamic {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DYNAMIC]);
    verify([source]);
  }

  void test_implementsEnum() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE }
class A implements E {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_ENUM]);
    verify([source]);
  }

  void test_implementsNonClass_class() {
    Source source = addSource(r'''
int A;
class B implements A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }

  void test_implementsNonClass_typeAlias() {
    Source source = addSource(r'''
class A {}
class M {}
int B;
class C = A with M implements B;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }

  void test_implementsRepeated() {
    Source source = addSource(r'''
class A {}
class B implements A, A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }

  void test_implementsRepeated_3times() {
    Source source = addSource(r'''
class A {} class C{}
class B implements A, A, A, A {}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.IMPLEMENTS_REPEATED,
            CompileTimeErrorCode.IMPLEMENTS_REPEATED,
            CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }

  void test_implementsSuperClass() {
    Source source = addSource(r'''
class A {}
class B extends A implements A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
    verify([source]);
  }

  void test_implementsSuperClass_Object() {
    Source source = addSource("class A implements Object {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_field() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
  var f;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_field2() {
    Source source = addSource(r'''
class A {
  final x = 0;
  final y = x;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_invocation() {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f();
  f() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_invocationInStatic() {
    Source source = addSource(r'''
class A {
  static var F = m();
  m() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void
      test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() {
    Source source = addSource(r'''
class A {
  A(p) {}
  A.named() : this(f);
  var f;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_implicitThisReferenceInInitializer_superConstructorInvocation() {
    Source source = addSource(r'''
class A {
  A(p) {}
}
class B extends A {
  B() : super(f);
  var f;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_importInternalLibrary() {
    Source source = addSource("import 'dart:_interceptors';");
    resolve(source);
    // Note, in these error cases we may generate an UNUSED_IMPORT hint, while
    // we could prevent the hint from being generated by testing the import
    // directive for the error, this is such a minor corner case that we don't
    // think we should add the additional computation time to figure out such
    // cases.
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, HintCode.UNUSED_IMPORT]);
    verify([source]);
  }

  void test_importInternalLibrary_js_helper() {
    Source source = addSource("import 'dart:_js_helper';");
    resolve(source);
    // Note, in these error cases we may generate an UNUSED_IMPORT hint, while
    // we could prevent the hint from being generated by testing the import
    // directive for the error, this is such a minor corner case that we don't
    // think we should add the additional computation time to figure out such
    // cases.
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, HintCode.UNUSED_IMPORT]);
    verify([source]);
  }

  void test_importOfNonLibrary() {
    Source source = addSource(r'''
library lib;
import 'part.dart';
A a;''');
    addNamedSource("/part.dart", r'''
part of lib;
class A{}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
    verify([source]);
  }

  void test_inconsistentCaseExpressionTypes() {
    Source source = addSource(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 'a':
      break;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }

  void test_inconsistentCaseExpressionTypes_dynamic() {
    // Even though A.S and S have a static type of "dynamic", we should see
    // that they fail to match 3, because they are constant strings.
    Source source = addSource(r'''
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
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
            CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }

  void test_inconsistentCaseExpressionTypes_repeated() {
    Source source = addSource(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 'a':
      break;
    case 'b':
      break;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
            CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }

  void test_initializerForNonExistent_const() {
    // Check that the absence of a matching field doesn't cause a
    // crash during constant evaluation.
    Source source = addSource(r'''
class A {
  const A() : x = 'foo';
}
A a = const A();''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD]);
  }

  void test_initializerForNonExistent_initializer() {
    Source source = addSource(r'''
class A {
  A() : x = 0 {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD]);
  }

  void test_initializerForStaticField() {
    Source source = addSource(r'''
class A {
  static int x;
  A() : x = 0 {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD]);
    verify([source]);
  }

  void test_initializingFormalForNonExistentField() {
    Source source = addSource(r'''
class A {
  A(this.x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  void test_initializingFormalForNonExistentField_notInEnclosingClass() {
    Source source = addSource(r'''
class A {
int x;
}
class B extends A {
  B(this.x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  void test_initializingFormalForNonExistentField_optional() {
    Source source = addSource(r'''
class A {
  A([this.x]) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  void test_initializingFormalForNonExistentField_synthetic() {
    Source source = addSource(r'''
class A {
  int get x => 1;
  A(this.x) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  void test_initializingFormalForStaticField() {
    Source source = addSource(r'''
class A {
  static int x;
  A([this.x]) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD]);
    verify([source]);
  }

  void test_instanceMemberAccessFromFactory_named() {
    Source source = addSource(r'''
class A {
  m() {}
  A();
  factory A.make() {
    m();
    return new A();
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY]);
    verify([source]);
  }

  void test_instanceMemberAccessFromFactory_unnamed() {
    Source source = addSource(r'''
class A {
  m() {}
  A._();
  factory A() {
    m();
    return new A._();
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY]);
    verify([source]);
  }

  void test_instanceMemberAccessFromStatic_field() {
    Source source = addSource(r'''
class A {
  int f;
  static foo() {
    f;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
    verify([source]);
  }

  void test_instanceMemberAccessFromStatic_getter() {
    Source source = addSource(r'''
class A {
  get g => null;
  static foo() {
    g;
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
    verify([source]);
  }

  void test_instanceMemberAccessFromStatic_method() {
    Source source = addSource(r'''
class A {
  m() {}
  static foo() {
    m();
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
    verify([source]);
  }

  void test_instantiateEnum_const() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE }
E e(String name) {
  return const E();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INSTANTIATE_ENUM]);
    verify([source]);
  }

  void test_instantiateEnum_new() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE }
E e(String name) {
  return new E();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INSTANTIATE_ENUM]);
    verify([source]);
  }

  void test_invalidAnnotation_getter() {
    Source source = addSource(r'''
get V => 0;
@V
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void test_invalidAnnotation_importWithPrefix_getter() {
    addNamedSource("/lib.dart", r'''
library lib;
get V => 0;''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.V
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void test_invalidAnnotation_importWithPrefix_notConstantVariable() {
    addNamedSource("/lib.dart", r'''
library lib;
final V = 0;''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.V
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void
      test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() {
    addNamedSource("/lib.dart", r'''
library lib;
typedef V();''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.V
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void test_invalidAnnotation_notConstantVariable() {
    Source source = addSource(r'''
final V = 0;
@V
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void test_invalidAnnotation_notVariableOrConstructorInvocation() {
    Source source = addSource(r'''
typedef V();
@V
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void test_invalidAnnotation_staticMethodReference() {
    Source source = addSource(r'''
class A {
  static f() {}
}
@A.f
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  void test_invalidAnnotation_unresolved_identifier() {
    Source source = addSource(r'''
@unresolved
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  void test_invalidAnnotation_unresolved_invocation() {
    Source source = addSource(r'''
@Unresolved()
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  void test_invalidAnnotation_unresolved_prefixedIdentifier() {
    Source source = addSource(r'''
import 'dart:math' as p;
@p.unresolved
main() {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  void test_invalidAnnotation_useLibraryScope() {
    Source source = addSource(r'''
@foo
class A {
  static const foo = null;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  void test_invalidAnnotationFromDeferredLibrary() {
    // See test_invalidAnnotation_notConstantVariable
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class V { const V(); }
const v = const V();''', r'''
library root;
import 'lib1.dart' deferred as a;
@a.v main () {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY]);
  }

  void test_invalidAnnotationFromDeferredLibrary_constructor() {
    // See test_invalidAnnotation_notConstantVariable
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class C { const C(); }''', r'''
library root;
import 'lib1.dart' deferred as a;
@a.C() main () {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY]);
  }

  void test_invalidAnnotationFromDeferredLibrary_namedConstructor() {
    // See test_invalidAnnotation_notConstantVariable
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class C { const C.name(); }''', r'''
library root;
import 'lib1.dart' deferred as a;
@a.C.name() main () {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY]);
  }

  void test_invalidConstructorName_notEnclosingClassName_defined() {
    Source source = addSource(r'''
class A {
  B() : super();
}
class B {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
    // no verify() call, "B" is not resolved
  }

  void test_invalidConstructorName_notEnclosingClassName_undefined() {
    Source source = addSource(r'''
class A {
  B() : super();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
    // no verify() call, "B" is not resolved
  }

  void test_invalidFactoryNameNotAClass_notClassName() {
    Source source = addSource(r'''
int B;
class A {
  factory B() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
    verify([source]);
  }

  void test_invalidFactoryNameNotAClass_notEnclosingClassName() {
    Source source = addSource(r'''
class A {
  factory B() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
    // no verify() call, "B" is not resolved
  }

  void test_invalidModifierOnConstructor_async() {
    resetWithAsync();
    Source source = addSource(r'''
class A {
  A() async {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
    verify([source]);
  }

  void test_invalidModifierOnConstructor_asyncStar() {
    resetWithAsync();
    Source source = addSource(r'''
class A {
  A() async* {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
    verify([source]);
  }

  void test_invalidModifierOnConstructor_syncStar() {
    resetWithAsync();
    Source source = addSource(r'''
class A {
  A() sync* {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
    verify([source]);
  }

  void test_invalidModifierOnSetter_member_async() {
    resetWithAsync();
    Source source = addSource(r'''
class A {
  set x(v) async {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  void test_invalidModifierOnSetter_member_asyncStar() {
    resetWithAsync();
    Source source = addSource(r'''
class A {
  set x(v) async* {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  void test_invalidModifierOnSetter_member_syncStar() {
    resetWithAsync();
    Source source = addSource(r'''
class A {
  set x(v) sync* {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  void test_invalidModifierOnSetter_topLevel_async() {
    resetWithAsync();
    Source source = addSource("set x(v) async {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  void test_invalidModifierOnSetter_topLevel_asyncStar() {
    resetWithAsync();
    Source source = addSource("set x(v) async* {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  void test_invalidModifierOnSetter_topLevel_syncStar() {
    resetWithAsync();
    Source source = addSource("set x(v) sync* {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  void test_invalidReferenceToThis_factoryConstructor() {
    Source source = addSource(r'''
class A {
  factory A() { return this; }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_instanceVariableInitializer_inConstructor() {
    Source source = addSource(r'''
class A {
  var f;
  A() : f = this;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration() {
    Source source = addSource(r'''
class A {
  var f = this;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_staticMethod() {
    Source source = addSource(r'''
class A {
  static m() { return this; }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_staticVariableInitializer() {
    Source source = addSource(r'''
class A {
  static A f = this;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_superInitializer() {
    Source source = addSource(r'''
class A {
  A(var x) {}
}
class B extends A {
  B() : super(this);
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_topLevelFunction() {
    Source source = addSource("f() { return this; }");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidReferenceToThis_variableInitializer() {
    Source source = addSource("int x = this;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  void test_invalidTypeArgumentInConstList() {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <E>[];
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST]);
    verify([source]);
  }

  void test_invalidTypeArgumentInConstMap() {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <String, E>{};
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
    verify([source]);
  }

  void test_invalidUri_export() {
    Source source = addSource("export 'ht:';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_URI]);
  }

  void test_invalidUri_import() {
    Source source = addSource("import 'ht:';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_URI]);
  }

  void test_invalidUri_part() {
    Source source = addSource("part 'ht:';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_URI]);
  }

  void test_isInConstInstanceCreation_restored() {
    // If ErrorVerifier._isInConstInstanceCreation is not properly restored on
    // exit from visitInstanceCreationExpression, the error at (1) will be
    // treated as a warning rather than an error.
    Source source = addSource(r'''
class Foo<T extends num> {
  const Foo(x, y);
}
const x = const Foo<int>(const Foo<int>(0, 1),
    const <Foo<String>>[]); // (1)
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_isInInstanceVariableInitializer_restored() {
    // If ErrorVerifier._isInInstanceVariableInitializer is not properly
    // restored on exit from visitVariableDeclaration, the error at (1)
    // won't be detected.
    Source source = addSource(r'''
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
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_labelInOuterScope() {
    Source source = addSource(r'''
class A {
  void m(int i) {
    l: while (i > 0) {
      void f() {
        break l;
      };
    }
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE]);
    // We cannot verify resolution with unresolvable labels
  }

  void test_labelUndefined_break() {
    Source source = addSource(r'''
f() {
  x: while (true) {
    break y;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.LABEL_UNDEFINED]);
    // We cannot verify resolution with undefined labels
  }

  void test_labelUndefined_continue() {
    Source source = addSource(r'''
f() {
  x: while (true) {
    continue y;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.LABEL_UNDEFINED]);
    // We cannot verify resolution with undefined labels
  }

  void test_memberWithClassName_field() {
    Source source = addSource(r'''
class A {
  int A = 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }

  void test_memberWithClassName_field2() {
    Source source = addSource(r'''
class A {
  int z, A, b = 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }

  void test_memberWithClassName_getter() {
    Source source = addSource(r'''
class A {
  get A => 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }

  void test_memberWithClassName_method() {
    // no test because indistinguishable from constructor
  }

  void test_methodAndGetterWithSameName() {
    Source source = addSource(r'''
class A {
  get x => 0;
  x(y) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME]);
    verify([source]);
  }

  void test_missingEnumConstantInSwitch() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE, TWO, THREE, FOUR }
bool odd(E e) {
  switch (e) {
    case E.ONE:
    case E.THREE: return true;
  }
  return false;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.MISSING_ENUM_CONSTANT_IN_SWITCH,
            CompileTimeErrorCode.MISSING_ENUM_CONSTANT_IN_SWITCH]);
    verify([source]);
  }

  void test_mixinDeclaresConstructor_classDeclaration() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends Object with A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  void test_mixinDeclaresConstructor_typeAlias() {
    Source source = addSource(r'''
class A {
  A() {}
}
class B = Object with A;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  void test_mixinDeferredClass() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {}''', r'''
library root;
import 'lib1.dart' deferred as a;
class B extends Object with a.A {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.MIXIN_DEFERRED_CLASS]);
  }

  void test_mixinDeferredClass_classTypeAlias() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
class A {}''', r'''
library root;
import 'lib1.dart' deferred as a;
class B {}
class C = B with a.A;'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.MIXIN_DEFERRED_CLASS]);
  }

  void test_mixinHasNoConstructors_mixinApp() {
    Source source = addSource(r'''
class B {
  B({x});
}
class M {}
class C = B with M;
''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_mixinHasNoConstructors_mixinClass() {
    Source source = addSource(r'''
class B {
  B({x});
}
class M {}
class C extends B with M {}
''');
    // Note: the implicit call from C's default constructor to B() should not
    // generate a further error (despite the fact that it's not forwarded),
    // since CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS does a better job
    // of explaining the probem to the user.
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_mixinHasNoConstructors_mixinClass_explicitSuperCall() {
    Source source = addSource(r'''
class B {
  B({x});
}
class M {}
class C extends B with M {
  C() : super();
}
''');
    // Note: the explicit call from C() to B() should not generate a further
    // error (despite the fact that it's not forwarded), since
    // CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS does a better job of
    // explaining the error to the user.
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_mixinHasNoConstructors_mixinClass_implicitSuperCall() {
    Source source = addSource(r'''
class B {
  B({x});
}
class M {}
class C extends B with M {
  C();
}
''');
    // Note: the implicit call from C() to B() should not generate a further
    // error (despite the fact that it's not forwarded), since
    // CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS does a better job of
    // explaining the error to the user.
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_mixinHasNoConstructors_mixinClass_namedSuperCall() {
    Source source = addSource(r'''
class B {
  B.named({x});
}
class M {}
class C extends B with M {
  C() : super.named();
}
''');
    // Note: the explicit call from C() to B.named() should not generate a
    // further error (despite the fact that it's not forwarded), since
    // CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS does a better job of
    // explaining the error to the user.
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_classDeclaration_extends() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C extends Object with B {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_classDeclaration_with() {
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_typeAlias_extends() {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C = Object with B;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  void test_mixinInheritsFromNotObject_typeAlias_with() {
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C = Object with B;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_class_bool() {
    Source source = addSource("class A extends Object with bool {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_class_double() {
    Source source = addSource("class A extends Object with double {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_class_int() {
    Source source = addSource("class A extends Object with int {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_class_Null() {
    Source source = addSource("class A extends Object with Null {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_class_num() {
    Source source = addSource("class A extends Object with num {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_class_String() {
    Source source = addSource("class A extends Object with String {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_bool() {
    Source source = addSource(r'''
class A {}
class C = A with bool;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_double() {
    Source source = addSource(r'''
class A {}
class C = A with double;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_int() {
    Source source = addSource(r'''
class A {}
class C = A with int;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_Null() {
    Source source = addSource(r'''
class A {}
class C = A with Null;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_num() {
    Source source = addSource(r'''
class A {}
class C = A with num;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_String() {
    Source source = addSource(r'''
class A {}
class C = A with String;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfDisallowedClass_classTypeAlias_String_num() {
    Source source = addSource(r'''
class A {}
class C = A with String, num;''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
            CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  void test_mixinOfEnum() {
    resetWithEnum();
    Source source = addSource(r'''
enum E { ONE }
class A extends Object with E {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_ENUM]);
    verify([source]);
  }

  void test_mixinOfNonClass_class() {
    Source source = addSource(r'''
int A;
class B extends Object with A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }

  void test_mixinOfNonClass_typeAlias() {
    Source source = addSource(r'''
class A {}
int B;
class C = A with B;''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }

  void test_mixinReferencesSuper() {
    Source source = addSource(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
    verify([source]);
  }

  void test_mixinWithNonClassSuperclass_class() {
    Source source = addSource(r'''
int A;
class B {}
class C extends A with B {}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }

  void test_mixinWithNonClassSuperclass_typeAlias() {
    Source source = addSource(r'''
int A;
class B {}
class C = A with B;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }

  void test_multipleRedirectingConstructorInvocations() {
    Source source = addSource(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS]);
    verify([source]);
  }

  void test_multipleSuperInitializers() {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() : super(), super() {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS]);
    verify([source]);
  }

  void test_nativeClauseInNonSDKCode() {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    Source source = addSource("class A native 'string' {}");
    resolve(source);
    assertErrors(source, [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
    verify([source]);
  }

  void test_nativeFunctionBodyInNonSDKCode_function() {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    Source source = addSource("int m(a) native 'string';");
    resolve(source);
    assertErrors(
        source,
        [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }

  void test_nativeFunctionBodyInNonSDKCode_method() {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    Source source = addSource(r'''
class A{
  static int m(a) native 'string';
}''');
    resolve(source);
    assertErrors(
        source,
        [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }

  void test_noAnnotationConstructorArguments() {
    Source source = addSource(r'''
class A {
  const A();
}
@A
main() {
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit() {
    Source source = addSource(r'''
class A {
  A(p);
}
class B extends A {
  B() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall() {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {
  C(x) : super();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam() {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {
  C();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall() {
    Source source = addSource(r'''
class M {}
class B {
  B.named({x});
  B.named2(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {
  C(x) : super.named();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    // Don't verify since call to super.named() can't be resolved.
  }

  void test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam() {
    Source source = addSource(r'''
class M {}
class B {
  B([x]);
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {
  C();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall() {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.other();
}
class C extends B with M {
  C(x) : super();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit_mixinWithNamedParam() {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.named();
}
class C extends B with M {
  C();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall() {
    Source source = addSource(r'''
class M {}
class B {
  B.named({x});
  B.other();
}
class C extends B with M {
  C(x) : super.named();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    // Don't verify since call to super.named() can't be resolved.
  }

  void test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam() {
    Source source = addSource(r'''
class M {}
class B {
  B([x]);
  B.other();
}
class C extends B with M {
  C();
}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam() {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam() {
    Source source = addSource(r'''
class M {}
class B {
  B([x]);
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorImplicit_mixinWithNamedParam() {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.other();
}
class C extends B with M {}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam() {
    Source source = addSource(r'''
class M {}
class B {
  B([x]);
  B.other();
}
class C extends B with M {}
''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorImplicit_superHasParameters() {
    Source source = addSource(r'''
class A {
  A(p);
}
class B extends A {
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_noDefaultSuperConstructorImplicit_superOnlyNamed() {
    Source source = addSource(r'''
class A { A.named() {} }
class B extends A {}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  void test_nonConstantAnnotationConstructor_named() {
    Source source = addSource(r'''
class A {
  A.fromInt() {}
}
@A.fromInt()
main() {
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR]);
    verify([source]);
  }

  void test_nonConstantAnnotationConstructor_unnamed() {
    Source source = addSource(r'''
class A {
  A() {}
}
@A()
main() {
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR]);
    verify([source]);
  }

  void test_nonConstantDefaultValue_function_named() {
    Source source = addSource(r'''
int y;
f({x : y}) {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  void test_nonConstantDefaultValue_function_positional() {
    Source source = addSource(r'''
int y;
f([x = y]) {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  void test_nonConstantDefaultValue_inConstructor_named() {
    Source source = addSource(r'''
class A {
  int y;
  A({x : y}) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  void test_nonConstantDefaultValue_inConstructor_positional() {
    Source source = addSource(r'''
class A {
  int y;
  A([x = y]) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  void test_nonConstantDefaultValue_method_named() {
    Source source = addSource(r'''
class A {
  int y;
  m({x : y}) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  void test_nonConstantDefaultValue_method_positional() {
    Source source = addSource(r'''
class A {
  int y;
  m([x = y]) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  void test_nonConstantDefaultValueFromDeferredLibrary() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const V = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V}) {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstantDefaultValueFromDeferredLibrary_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const V = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V + 1}) {}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstCaseExpression() {
    Source source = addSource(r'''
f(int p, int q) {
  switch (p) {
    case 3 + q:
      break;
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION]);
    verify([source]);
  }

  void test_nonConstCaseExpressionFromDeferredLibrary() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c:
      break;
  }
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstCaseExpressionFromDeferredLibrary_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c + 1:
      break;
  }
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstListElement() {
    Source source = addSource(r'''
f(a) {
  return const [a];
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
    verify([source]);
  }

  void test_nonConstListElementFromDeferredLibrary() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const [a.c];
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstListElementFromDeferredLibrary_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const [a.c + 1];
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstMapAsExpressionStatement_begin() {
    Source source = addSource(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }

  void test_nonConstMapAsExpressionStatement_only() {
    Source source = addSource(r'''
f() {
  {'a' : 0, 'b' : 1};
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }

  void test_nonConstMapKey() {
    Source source = addSource(r'''
f(a) {
  return const {a : 0};
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
    verify([source]);
  }

  void test_nonConstMapKeyFromDeferredLibrary() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c : 0};
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstMapKeyFromDeferredLibrary_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c + 1 : 0};
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstMapValue() {
    Source source = addSource(r'''
f(a) {
  return const {'a' : a};
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
    verify([source]);
  }

  void test_nonConstMapValueFromDeferredLibrary() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {'a' : a.c};
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstMapValueFromDeferredLibrary_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {'a' : a.c + 1};
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstValueInInitializer_binary_notBool_left() {
    Source source = addSource(r'''
class A {
  final bool a;
  const A(String p) : a = p && true;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
            StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_binary_notBool_right() {
    Source source = addSource(r'''
class A {
  final bool a;
  const A(String p) : a = true && p;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
            StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_binary_notInt() {
    Source source = addSource(r'''
class A {
  final int a;
  const A(String p) : a = 5 & p;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_INT,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_binary_notNum() {
    Source source = addSource(r'''
class A {
  final int a;
  const A(String p) : a = 5 + p;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_NUM,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_field() {
    Source source = addSource(r'''
class A {
  static int C;
  final int a;
  const A() : a = C;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_instanceCreation() {
    Source source = addSource(r'''
class A {
  A();
}
class B {
  const B() : a = new A();
  final a;
}
var b = const B();''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_redirecting() {
    Source source = addSource(r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_nonConstValueInInitializer_super() {
    Source source = addSource(r'''
class A {
  const A(p);
}
class B extends A {
  static var C;
  const B() : super(C);
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  void test_nonConstValueInInitializerFromDeferredLibrary_field() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c;
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstValueInInitializerFromDeferredLibrary_field_nested() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstValueInInitializerFromDeferredLibrary_redirecting() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonConstValueInInitializerFromDeferredLibrary_super() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
const int c = 1;''', r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
}'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[
              CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY]);
  }

  void test_nonGenerativeConstructor_explicit() {
    Source source = addSource(r'''
class A {
  factory A.named() {}
}
class B extends A {
  B() : super.named();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_nonGenerativeConstructor_implicit() {
    Source source = addSource(r'''
class A {
  factory A() {}
}
class B extends A {
  B();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_nonGenerativeConstructor_implicit2() {
    Source source = addSource(r'''
class A {
  factory A() {}
}
class B extends A {
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_notEnoughRequiredArguments_const() {
    Source source = addSource(r'''
class A {
  const A(int p);
}
main() {
  const A();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  void test_notEnoughRequiredArguments_const_super() {
    Source source = addSource(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  void test_optionalParameterInOperator_named() {
    Source source = addSource(r'''
class A {
  operator +({p}) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }

  void test_optionalParameterInOperator_positional() {
    Source source = addSource(r'''
class A {
  operator +([p]) {}
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }

  void test_partOfNonPart() {
    Source source = addSource(r'''
library l1;
part 'l2.dart';''');
    addNamedSource("/l2.dart", "library l2;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.PART_OF_NON_PART]);
    verify([source]);
  }

  void test_prefixCollidesWithTopLevelMembers_functionTypeAlias() {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
typedef p();
p.A a;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  void test_prefixCollidesWithTopLevelMembers_topLevelFunction() {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
p() {}
p.A a;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  void test_prefixCollidesWithTopLevelMembers_topLevelVariable() {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
var p = null;
p.A a;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  void test_prefixCollidesWithTopLevelMembers_type() {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
class p {}
p.A a;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  void test_privateOptionalParameter() {
    Source source = addSource("f({var _p}) {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }

  void test_privateOptionalParameter_fieldFormal() {
    Source source = addSource(r'''
class A {
  var _p;
  A({this._p: 0});
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }

  void test_privateOptionalParameter_withDefaultValue() {
    Source source = addSource("f({_p : 0}) {}");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }

  void test_recursiveConstructorRedirect() {
    Source source = addSource(r'''
class A {
  A.a() : this.b();
  A.b() : this.a();
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT]);
    verify([source]);
  }

  void test_recursiveConstructorRedirect_directSelfReference() {
    Source source = addSource(r'''
class A {
  A() : this();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT]);
    verify([source]);
  }

  void test_recursiveFactoryRedirect() {
    Source source = addSource(r'''
class A implements B {
  factory A() = C;
}
class B implements C {
  factory B() = A;
}
class C implements A {
  factory C() = B;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveFactoryRedirect_directSelfReference() {
    Source source = addSource(r'''
class A {
  factory A() = A;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
    verify([source]);
  }

  void test_recursiveFactoryRedirect_generic() {
    Source source = addSource(r'''
class A<T> implements B<T> {
  factory A() = C;
}
class B<T> implements C<T> {
  factory B() = A;
}
class C<T> implements A<T> {
  factory C() = B;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveFactoryRedirect_named() {
    Source source = addSource(r'''
class A implements B {
  factory A.nameA() = C.nameC;
}
class B implements C {
  factory B.nameB() = A.nameA;
}
class C implements A {
  factory C.nameC() = B.nameB;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  /**
   * "A" references "C" which has cycle with "B". But we should not report problem for "A" - it is
   * not the part of a cycle.
   */
  void test_recursiveFactoryRedirect_outsideCycle() {
    Source source = addSource(r'''
class A {
  factory A() = C;
}
class B implements C {
  factory B() = C;
}
class C implements A, B {
  factory C() = B;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_extends() {
    Source source = addSource(r'''
class A extends B {}
class B extends A {}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_extends_implements() {
    Source source = addSource(r'''
class A extends B {}
class B implements A {}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_implements() {
    Source source = addSource(r'''
class A implements B {}
class B implements A {}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_mixin() {
    Source source = addSource(r'''
class M1 = Object with M2;
class M2 = Object with M1;''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_tail() {
    Source source = addSource(r'''
abstract class A implements A {}
class B implements A {}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_tail2() {
    Source source = addSource(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritance_tail3() {
    Source source = addSource(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
            CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritanceBaseCaseExtends() {
    Source source = addSource("class A extends A {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritanceBaseCaseImplements() {
    Source source = addSource("class A implements A {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritanceBaseCaseImplements_typeAlias() {
    Source source = addSource(r'''
class A {}
class M {}
class B = A with M implements B;''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS]);
    verify([source]);
  }

  void test_recursiveInterfaceInheritanceBaseCaseWith() {
    Source source = addSource("class M = Object with M;");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH]);
    verify([source]);
  }

  void test_redirectGenerativeToMissingConstructor() {
    Source source = addSource(r'''
class A {
  A() : this.noSuchConstructor();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR]);
  }

  void test_redirectGenerativeToNonGenerativeConstructor() {
    Source source = addSource(r'''
class A {
  A() : this.x();
  factory A.x() => null;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_redirectToMissingConstructor_named() {
    Source source = addSource(r'''
class A implements B{
  A() {}
}
class B {
  const factory B() = A.name;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  void test_redirectToMissingConstructor_unnamed() {
    Source source = addSource(r'''
class A implements B{
  A.name() {}
}
class B {
  const factory B() = A;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  void test_redirectToNonClass_notAType() {
    Source source = addSource(r'''
int A;
class B {
  const factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  void test_redirectToNonClass_undefinedIdentifier() {
    Source source = addSource(r'''
class B {
  const factory B() = A;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  void test_redirectToNonConstConstructor() {
    Source source = addSource(r'''
class A {
  A.a() {}
  const factory A.b() = A.a;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR]);
    verify([source]);
  }

  void test_referencedBeforeDeclaration_hideInBlock_function() {
    Source source = addSource(r'''
var v = 1;
main() {
  print(v);
  v() {}
}
print(x) {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  void test_referencedBeforeDeclaration_hideInBlock_local() {
    Source source = addSource(r'''
var v = 1;
main() {
  print(v);
  var v = 2;
}
print(x) {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  void test_referencedBeforeDeclaration_hideInBlock_subBlock() {
    Source source = addSource(r'''
var v = 1;
main() {
  {
    print(v);
  }
  var v = 2;
}
print(x) {}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  void test_referencedBeforeDeclaration_inInitializer_closure() {
    Source source = addSource(r'''
main() {
  var v = () => v;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  void test_referencedBeforeDeclaration_inInitializer_directly() {
    Source source = addSource(r'''
main() {
  var v = v;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  void test_rethrowOutsideCatch() {
    Source source = addSource(r'''
f() {
  rethrow;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH]);
    verify([source]);
  }

  void test_returnInGenerativeConstructor() {
    Source source = addSource(r'''
class A {
  A() { return 0; }
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_returnInGenerativeConstructor_expressionFunctionBody() {
    Source source = addSource(r'''
class A {
  A() => null;
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  void test_returnInGenerator_asyncStar() {
    resetWithAsync();
    Source source = addSource(r'''
f() async* {
  return 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.RETURN_IN_GENERATOR]);
    verify([source]);
  }

  void test_returnInGenerator_syncStar() {
    resetWithAsync();
    Source source = addSource(r'''
f() sync* {
  return 0;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.RETURN_IN_GENERATOR]);
    verify([source]);
  }

  void test_sharedDeferredPrefix() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
f1() {}''', r'''
library lib2;
f2() {}''', r'''
library root;
import 'lib1.dart' deferred as lib;
import 'lib2.dart' as lib;
main() { lib.f1(); lib.f2(); }'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[CompileTimeErrorCode.SHARED_DEFERRED_PREFIX]);
  }

  void test_superInInvalidContext_binaryExpression() {
    Source source = addSource("var v = super + 0;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.v' is not resolved
  }

  void test_superInInvalidContext_constructorFieldInitializer() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  var f;
  B() : f = super.m();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.m' is not resolved
  }

  void test_superInInvalidContext_factoryConstructor() {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  factory B() {
    super.m();
  }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.m' is not resolved
  }

  void test_superInInvalidContext_instanceVariableInitializer() {
    Source source = addSource(r'''
class A {
  var a;
}
class B extends A {
 var b = super.a;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.a' is not resolved
  }

  void test_superInInvalidContext_staticMethod() {
    Source source = addSource(r'''
class A {
  static m() {}
}
class B extends A {
  static n() { return super.m(); }
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.m' is not resolved
  }

  void test_superInInvalidContext_staticVariableInitializer() {
    Source source = addSource(r'''
class A {
  static int a = 0;
}
class B extends A {
  static int b = super.a;
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.a' is not resolved
  }

  void test_superInInvalidContext_topLevelFunction() {
    Source source = addSource(r'''
f() {
  super.f();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.f' is not resolved
  }

  void test_superInInvalidContext_topLevelVariableInitializer() {
    Source source = addSource("var v = super.y;");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.y' is not resolved
  }

  void test_superInRedirectingConstructor_redirectionSuper() {
    Source source = addSource(r'''
class A {}
class B {
  B() : this.name(), super();
  B.name() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  void test_superInRedirectingConstructor_superRedirection() {
    Source source = addSource(r'''
class A {}
class B {
  B() : super(), this.name();
  B.name() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  void test_symbol_constructor_badArgs() {
    Source source = addSource(r'''
var s1 = const Symbol('3');
var s2 = const Symbol(3);
var s3 = const Symbol();
var s4 = const Symbol('x', 'y');
var s5 = const Symbol('x', foo: 'x');''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
            CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
            CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS,
            CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS,
            CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_11987() {
    Source source = addSource(r'''
typedef void F(List<G> l);
typedef void G(List<F> l);
main() {
  F foo(G g) => g;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
            CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
            StaticTypeWarningCode.RETURN_OF_INVALID_TYPE]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_19459() {
    // A complex example involving multiple classes.  This is legal, since
    // typedef F references itself only via a class.
    Source source = addSource(r'''
class A<B, C> {}
abstract class D {
  f(E e);
}
abstract class E extends A<dynamic, F> {}
typedef D F();
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_parameterType_named() {
    Source source = addSource("typedef A({A a});");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_parameterType_positional() {
    Source source = addSource("typedef A([A a]);");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_parameterType_required() {
    Source source = addSource("typedef A(A a);");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_parameterType_typeArgument() {
    Source source = addSource("typedef A(List<A> a);");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() {
    // A typedef is allowed to indirectly reference itself via a class.
    Source source = addSource(r'''
typedef C A();
typedef A B();
class C {
  B a;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_returnType() {
    Source source = addSource("typedef A A();");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_returnType_indirect() {
    Source source = addSource(r'''
typedef B A();
typedef A B();''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
            CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeAliasCannotReferenceItself_typeVariableBounds() {
    Source source = addSource("typedef A<T extends A>();");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  void test_typeArgumentNotMatchingBounds_const() {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  void test_undefinedClass_const() {
    Source source = addSource(r'''
f() {
  return const A();
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_explicit_named() {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() : super.named();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    // no verify(), "super.named()" is not resolved
  }

  void test_undefinedConstructorInInitializer_explicit_unnamed() {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_undefinedConstructorInInitializer_implicit() {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B extends A {
  B();
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  void test_undefinedNamedParameter() {
    Source source = addSource(r'''
class A {
  const A();
}
main() {
  const A(p: 0);
}''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER]);
    // no verify(), 'p' is not resolved
  }

  void test_uriDoesNotExist_export() {
    Source source = addSource("export 'unknown.dart';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  void test_uriDoesNotExist_import() {
    Source source = addSource("import 'unknown.dart';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  void test_uriDoesNotExist_part() {
    Source source = addSource("part 'unknown.dart';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  void test_uriWithInterpolation_constant() {
    Source source = addSource("import 'stuff_\$platform.dart';");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.URI_WITH_INTERPOLATION,
            StaticWarningCode.UNDEFINED_IDENTIFIER]);
    // We cannot verify resolution with an unresolvable
    // URI: 'stuff_$platform.dart'
  }

  void test_uriWithInterpolation_nonConstant() {
    Source source = addSource(r'''
library lib;
part '${'a'}.dart';''');
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.URI_WITH_INTERPOLATION]);
    // We cannot verify resolution with an unresolvable URI: '${'a'}.dart'
  }

  void test_wrongNumberOfParametersForOperator1() {
    _check_wrongNumberOfParametersForOperator1("<");
    _check_wrongNumberOfParametersForOperator1(">");
    _check_wrongNumberOfParametersForOperator1("<=");
    _check_wrongNumberOfParametersForOperator1(">=");
    _check_wrongNumberOfParametersForOperator1("+");
    _check_wrongNumberOfParametersForOperator1("/");
    _check_wrongNumberOfParametersForOperator1("~/");
    _check_wrongNumberOfParametersForOperator1("*");
    _check_wrongNumberOfParametersForOperator1("%");
    _check_wrongNumberOfParametersForOperator1("|");
    _check_wrongNumberOfParametersForOperator1("^");
    _check_wrongNumberOfParametersForOperator1("&");
    _check_wrongNumberOfParametersForOperator1("<<");
    _check_wrongNumberOfParametersForOperator1(">>");
    _check_wrongNumberOfParametersForOperator1("[]");
  }

  void test_wrongNumberOfParametersForOperator_minus() {
    Source source = addSource(r'''
class A {
  operator -(a, b) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS]);
    verify([source]);
    reset();
  }

  void test_wrongNumberOfParametersForOperator_tilde() {
    _check_wrongNumberOfParametersForOperator("~", "a");
    _check_wrongNumberOfParametersForOperator("~", "a, b");
  }

  void test_wrongNumberOfParametersForSetter_function_named() {
    Source source = addSource("set x({p}) {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_function_optional() {
    Source source = addSource("set x([p]) {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_function_tooFew() {
    Source source = addSource("set x() {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_function_tooMany() {
    Source source = addSource("set x(a, b) {}");
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_method_named() {
    Source source = addSource(r'''
class A {
  set x({p}) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_method_optional() {
    Source source = addSource(r'''
class A {
  set x([p]) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_method_tooFew() {
    Source source = addSource(r'''
class A {
  set x() {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void test_wrongNumberOfParametersForSetter_method_tooMany() {
    Source source = addSource(r'''
class A {
  set x(a, b) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  void _check_constEvalThrowsException_binary_null(String expr, bool resolved) {
    Source source = addSource("const C = $expr;");
    resolve(source);
    if (resolved) {
      assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
      verify([source]);
    } else {
      assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
      // no verify(), 'null x' is not resolved
    }
    reset();
  }

  void _check_constEvalTypeBool_withParameter_binary(String expr) {
    Source source = addSource('''
class A {
  final a;
  const A(bool p) : a = $expr;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
            StaticTypeWarningCode.NON_BOOL_OPERAND]);
    verify([source]);
    reset();
  }

  void _check_constEvalTypeInt_withParameter_binary(String expr) {
    Source source = addSource('''
class A {
  final a;
  const A(int p) : a = $expr;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_INT,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
    reset();
  }

  void _check_constEvalTypeNum_withParameter_binary(String expr) {
    Source source = addSource('''
class A {
  final a;
  const A(num p) : a = $expr;
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.CONST_EVAL_TYPE_NUM,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
    reset();
  }

  void _check_wrongNumberOfParametersForOperator(String name,
      String parameters) {
    Source source = addSource('''
class A {
  operator $name($parameters) {}
}''');
    resolve(source);
    assertErrors(
        source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR]);
    verify([source]);
    reset();
  }

  void _check_wrongNumberOfParametersForOperator1(String name) {
    _check_wrongNumberOfParametersForOperator(name, "");
    _check_wrongNumberOfParametersForOperator(name, "a, b");
  }
}
