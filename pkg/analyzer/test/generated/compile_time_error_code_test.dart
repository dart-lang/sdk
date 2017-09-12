// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.compile_time_error_code_test;

import 'dart:async';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:test/test.dart' show expect;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest extends ResolverTestCase {
  fail_awaitInWrongContext_sync() async {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    Source source = addSource(r'''
f(x) {
  return await x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT]);
    verify([source]);
  }

  fail_awaitInWrongContext_syncStar() async {
    // This test requires better error recovery than we currently have. In
    // particular, we need to be able to distinguish between an await expression
    // in the wrong context, and the use of 'await' as an identifier.
    Source source = addSource(r'''
f(x) sync* {
  yield await x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT]);
    verify([source]);
  }

  fail_constEvalThrowsException() async {
    Source source = addSource(r'''
class C {
  const C();
}
f() { return const C(); }''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_THROWS_EXCEPTION]);
    verify([source]);
  }

  fail_invalidIdentifierInAsync_async() async {
    // TODO(brianwilkerson) Report this error.
    Source source = addSource(r'''
class A {
  m() async {
    int async;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC]);
    verify([source]);
  }

  fail_invalidIdentifierInAsync_await() async {
    // TODO(brianwilkerson) Report this error.
    Source source = addSource(r'''
class A {
  m() async {
    int await;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC]);
    verify([source]);
  }

  fail_invalidIdentifierInAsync_yield() async {
    // TODO(brianwilkerson) Report this error.
    Source source = addSource(r'''
class A {
  m() async {
    int yield;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_IDENTIFIER_IN_ASYNC]);
    verify([source]);
  }

  fail_mixinDeclaresConstructor() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends Object mixin A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  fail_mixinOfNonClass() async {
    // TODO(brianwilkerson) Compare with MIXIN_WITH_NON_CLASS_SUPERCLASS.
    Source source = addSource(r'''
var A;
class B extends Object mixin A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }

  fail_objectCannotExtendAnotherClass() async {
    Source source = addSource(r'''
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.OBJECT_CANNOT_EXTEND_ANOTHER_CLASS]);
    verify([source]);
  }

  fail_superInitializerInObject() async {
    Source source = addSource(r'''
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_INITIALIZER_IN_OBJECT]);
    verify([source]);
  }

  fail_yieldEachInNonGenerator_async() async {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    Source source = addSource(r'''
f() async {
  yield* 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR]);
    verify([source]);
  }

  fail_yieldEachInNonGenerator_sync() async {
    // TODO(brianwilkerson) We are currently parsing the yield statement as a
    // binary expression.
    Source source = addSource(r'''
f() {
  yield* 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_IN_NON_GENERATOR]);
    verify([source]);
  }

  fail_yieldInNonGenerator_async() async {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    Source source = addSource(r'''
f() async {
  yield 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_IN_NON_GENERATOR]);
    verify([source]);
  }

  fail_yieldInNonGenerator_sync() async {
    // TODO(brianwilkerson) We are currently trying to parse the yield statement
    // as a binary expression.
    Source source = addSource(r'''
f() {
  yield 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.YIELD_EACH_IN_NON_GENERATOR]);
    verify([source]);
  }

  test_accessPrivateEnumField() async {
    Source source = addSource(r'''
enum E { ONE }
String name(E e) {
  return e._name;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD]);
    // Cannot verify because "_name" cannot be resolved.
  }

  test_ambiguousExport() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.AMBIGUOUS_EXPORT]);
    verify([source]);
  }

  test_annotationWithNotClass() async {
    Source source = addSource('''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);

@property(123)
main() {
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS]);
    verify([source]);
  }

  test_annotationWithNotClass_prefixed() async {
    addNamedSource("/annotations.dart", r'''
class Property {
  final int value;
  const Property(this.value);
}

const Property property = const Property(42);
''');
    Source source = addSource('''
import 'annotations.dart' as pref;
@pref.property(123)
main() {
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS]);
    verify([source]);
  }

  test_async_used_as_identifier_in_annotation() async {
    Source source = addSource('''
const int async = 0;
f() async {
  g(@async x) {}
  g(0);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_argument_label() async {
    Source source = addSource('''
@proxy
class C {}
f() async {
  new C().g(async: 0);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    // Note: we don't call verify([source]) because verify() doesn't understand
    // about @proxy.
  }

  test_async_used_as_identifier_in_async_method() async {
    Source source = addSource('''
f() async {
  var async = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_async_star_method() async {
    Source source = addSource('''
f() async* {
  var async = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_break_statement() async {
    Source source = addSource('''
f() async {
  while (true) {
    break async;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER,
      CompileTimeErrorCode.LABEL_UNDEFINED
    ]);
    // Note: we don't call verify([source]) because the reference to the
    // "async" label is unresolved.
  }

  test_async_used_as_identifier_in_cascaded_invocation() async {
    Source source = addSource('''
class C {
  int async() => 1;
}
f() async {
  return new C()..async();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_cascaded_setter_invocation() async {
    Source source = addSource('''
class C {
  void set async(int i) {}
}
f() async {
  return new C()..async = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_catch_exception_argument() async {
    Source source = addSource('''
g() {}
f() async {
  try {
    g();
  } catch (async) { }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_catch_stacktrace_argument() async {
    Source source = addSource('''
g() {}
f() async {
  try {
    g();
  } catch (e, async) { }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_continue_statement() async {
    Source source = addSource('''
f() async {
  while (true) {
    continue async;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER,
      CompileTimeErrorCode.LABEL_UNDEFINED
    ]);
    // Note: we don't call verify([source]) because the reference to the
    // "async" label is unresolved.
  }

  test_async_used_as_identifier_in_for_statement() async {
    Source source = addSource('''
var async;
f() async {
  for (async in []) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_formal_parameter_name() async {
    Source source = addSource('''
f() async {
  g(int async) {}
  g(0);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_getter_name() async {
    Source source = addSource('''
class C {
  int get async => 1;
}
f() async {
  return new C().async;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_invocation() async {
    Source source = addSource('''
class C {
  int async() => 1;
}
f() async {
  return new C().async();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_local_function_name() async {
    Source source = addSource('''
f() async {
  int async() => null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_prefix() async {
    Source source = addSource('''
import 'dart:async' as async;
f() async {
  return new async.Future.value(0);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_setter_name() async {
    Source source = addSource('''
class C {
  void set async(int i) {}
}
f() async {
  new C().async = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_statement_label() async {
    Source source = addSource('''
f() async {
  async: g();
}
g() {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_string_interpolation() async {
    Source source = addSource(r'''
int async = 1;
f() async {
  return "$async";
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_suffix() async {
    addNamedSource("/lib1.dart", r'''
library lib1;
int async;
''');
    Source source = addSource('''
import 'lib1.dart' as l;
f() async {
  return l.async;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_switch_label() async {
    Source source = addSource('''
f() async {
  switch (0) {
    async: case 0: break;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_async_used_as_identifier_in_sync_star_method() async {
    Source source = addSource('''
f() sync* {
  var async = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_asyncForInWrongContext() async {
    Source source = addSource(r'''
f(list) {
  await for (var e in list) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.ASYNC_FOR_IN_WRONG_CONTEXT]);
    verify([source]);
  }

  test_await_used_as_identifier_in_async_method() async {
    Source source = addSource('''
f() async {
  var await = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_await_used_as_identifier_in_async_star_method() async {
    Source source = addSource('''
f() async* {
  var await = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_await_used_as_identifier_in_sync_star_method() async {
    Source source = addSource('''
f() sync* {
  var await = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_bug_23176() async {
    Source source = addSource('''
class A {
  const A([x]);
}
class B {
  dynamic @A(const A()) x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      ParserErrorCode.EXPECTED_CLASS_MEMBER,
      ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE
    ]);
    verify([source]);
  }

  test_builtInIdentifierAsMixinName_classTypeAlias() async {
    Source source = addSource(r'''
class A {}
class B {}
class as = A with B;''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }

  test_builtInIdentifierAsPrefixName() async {
    Source source = addSource("import 'dart:async' as abstract;");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_PREFIX_NAME,
      HintCode.UNUSED_IMPORT
    ]);
    verify([source]);
  }

  test_builtInIdentifierAsType_formalParameter_field() async {
    Source source = addSource(r'''
class A {
  var x;
  A(static this.x);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    verify([source]);
  }

  test_builtInIdentifierAsType_formalParameter_simple() async {
    Source source = addSource(r'''
f(static x) {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    verify([source]);
  }

  test_builtInIdentifierAsType_variableDeclaration() async {
    Source source = addSource(r'''
f() {
  typedef x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE]);
    verify([source]);
  }

  test_builtInIdentifierAsTypedefName_functionTypeAlias() async {
    Source source = addSource("typedef bool as();");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPEDEF_NAME]);
    verify([source]);
  }

  test_builtInIdentifierAsTypeName() async {
    Source source = addSource("class as {}");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_NAME]);
    verify([source]);
  }

  test_builtInIdentifierAsTypeParameterName() async {
    Source source = addSource("class A<as> {}");
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.BUILT_IN_IDENTIFIER_AS_TYPE_PARAMETER_NAME]);
    verify([source]);
  }

  test_caseExpressionTypeImplementsEquals() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_conflictingConstructorNameAndMember_field() async {
    Source source = addSource(r'''
class A {
  int x;
  A.x() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD]);
    verify([source]);
  }

  test_conflictingConstructorNameAndMember_getter() async {
    Source source = addSource(r'''
class A {
  int get x => 42;
  A.x() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_FIELD]);
    verify([source]);
  }

  test_conflictingConstructorNameAndMember_method() async {
    Source source = addSource(r'''
class A {
  const A.x();
  void x() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_CONSTRUCTOR_NAME_AND_METHOD]);
    verify([source]);
  }

  test_conflictingGetterAndMethod_field_method() async {
    Source source = addSource(r'''
class A {
  final int m = 0;
}
class B extends A {
  m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD]);
    verify([source]);
  }

  test_conflictingGetterAndMethod_getter_method() async {
    Source source = addSource(r'''
class A {
  get m => 0;
}
class B extends A {
  m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_GETTER_AND_METHOD]);
    verify([source]);
  }

  test_conflictingGetterAndMethod_method_field() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  int m;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER]);
    verify([source]);
  }

  test_conflictingGetterAndMethod_method_getter() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  get m => 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONFLICTING_METHOD_AND_GETTER]);
    verify([source]);
  }

  test_conflictingTypeVariableAndClass() async {
    Source source = addSource(r'''
class T<T> {
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_CLASS]);
    verify([source]);
  }

  test_conflictingTypeVariableAndMember_field() async {
    Source source = addSource(r'''
class A<T> {
  var T;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  test_conflictingTypeVariableAndMember_getter() async {
    Source source = addSource(r'''
class A<T> {
  get T => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  test_conflictingTypeVariableAndMember_method() async {
    Source source = addSource(r'''
class A<T> {
  T() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  test_conflictingTypeVariableAndMember_method_static() async {
    Source source = addSource(r'''
class A<T> {
  static T() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  test_conflictingTypeVariableAndMember_setter() async {
    Source source = addSource(r'''
class A<T> {
  set T(x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONFLICTING_TYPE_VARIABLE_AND_MEMBER]);
    verify([source]);
  }

  test_consistentCaseExpressionTypes_dynamic() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_const_invalid_constructorFieldInitializer_fromLibrary() async {
    addNamedSource('/lib.dart', r'''
class A<T> {
  final int f;
  const A() : f = T.foo;
}
''');
    Source source = addSource(r'''
import 'lib.dart';
const a = const A();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
  }

  test_constConstructor_redirect_generic() async {
    Source source = addSource(r'''
class A<T> {
  const A(T value) : this._(value);
  const A._(T value) : value = value;
  final T value;
}

void main(){
  const A<int>(1);
}
''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithFieldInitializedByNonConst() async {
    Source source = addSource(r'''
class A {
  final int i = f();
  const A();
}
int f() {
  return 3;
}''');
    // TODO(paulberry): the error CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE is
    // redundant and ought to be suppressed.
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode
          .CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST,
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
    ]);
    verify([source]);
  }

  test_constConstructorWithFieldInitializedByNonConst_static() async {
    Source source = addSource(r'''
class A {
  static final int i = f();
  const A();
}
int f() {
  return 3;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constConstructorWithMixin() async {
    Source source = addSource(r'''
class M {
}
class A extends Object with M {
  const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN]);
    verify([source]);
  }

  test_constConstructorWithNonConstSuper_explicit() async {
    Source source = addSource(r'''
class A {
  A();
}
class B extends A {
  const B(): super();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
    verify([source]);
  }

  test_constConstructorWithNonConstSuper_implicit() async {
    Source source = addSource(r'''
class A {
  A();
}
class B extends A {
  const B();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER]);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_mixin() async {
    Source source = addSource(r'''
class A {
  var a;
}
class B extends Object with A {
  const B();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_MIXIN,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
    ]);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_super() async {
    Source source = addSource(r'''
class A {
  var a;
}
class B extends A {
  const B();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD,
      CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_CONST_SUPER
    ]);
    verify([source]);
  }

  test_constConstructorWithNonFinalField_this() async {
    Source source = addSource(r'''
class A {
  int x;
  const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD]);
    verify([source]);
  }

  test_constDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {
  const A();
}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main() {
  const a.A();
}'''
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
    Source source = addSource(r'''
class A {
  const A();
}
const a = new A();''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  test_constEval_newInstance_externalFactoryConstConstructor() async {
    // We can't evaluate "const A()" because its constructor is external.  But
    // the code is correct--we shouldn't report an error.
    Source source = addSource(r'''
class A {
  external factory const A();
}
const x = const A();''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_constEval_nonStaticField_inGenericClass() async {
    Source source = addSource('''
class C<T> {
  const C();
  T get t => null;
}

const x = const C().t;''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  test_constEval_propertyExtraction_targetNotConst() async {
    Source source = addSource(r'''
class A {
  const A();
  m() {}
}
final a = const A();
const C = a.m;''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  test_constEvalThrowsException_binaryMinus_null() async {
    await _check_constEvalThrowsException_binary_null("null - 5", false);
    await _check_constEvalThrowsException_binary_null("5 - null", true);
  }

  test_constEvalThrowsException_binaryPlus_null() async {
    await _check_constEvalThrowsException_binary_null("null + 5", false);
    await _check_constEvalThrowsException_binary_null("5 + null", true);
  }

  test_constEvalThrowsException_divisionByZero() async {
    Source source = addSource("const C = 1 ~/ 0;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_IDBZE]);
    verify([source]);
  }

  test_constEvalThrowsException_finalAlreadySet_initializer() async {
    // If a final variable has an initializer at the site of its declaration,
    // and at the site of the constructor, then invoking that constructor would
    // produce a runtime error; hence invoking that constructor via the "const"
    // keyword results in a compile-time error.
    Source source = addSource('''
class C {
  final x = 1;
  const C() : x = 2;
}
var x = const C();
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION
    ]);
    verify([source]);
  }

  test_constEvalThrowsException_finalAlreadySet_initializing_formal() async {
    // If a final variable has an initializer at the site of its declaration,
    // and it is initialized using an initializing formal at the site of the
    // constructor, then invoking that constructor would produce a runtime
    // error; hence invoking that constructor via the "const" keyword results
    // in a compile-time error.
    Source source = addSource('''
class C {
  final x = 1;
  const C(this.x);
}
var x = const C(2);
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.FINAL_INITIALIZED_IN_DECLARATION_AND_CONSTRUCTOR
    ]);
    verify([source]);
  }

  test_constEvalThrowsException_unaryBitNot_null() async {
    Source source = addSource("const C = ~null;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    // no verify(), '~null' is not resolved
  }

  test_constEvalThrowsException_unaryNegated_null() async {
    Source source = addSource("const C = -null;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    // no verify(), '-null' is not resolved
  }

  test_constEvalThrowsException_unaryNot_null() async {
    Source source = addSource("const C = !null;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
    verify([source]);
  }

  test_constEvalTypeBool_binary() async {
    await _check_constEvalTypeBool_withParameter_binary("p && ''");
    await _check_constEvalTypeBool_withParameter_binary("p || ''");
  }

  test_constEvalTypeBool_binary_leftTrue() async {
    Source source = addSource("const C = (true || 0);");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_OPERAND,
      HintCode.DEAD_CODE
    ]);
    verify([source]);
  }

  test_constEvalTypeBoolNumString_equal() async {
    Source source = addSource(r'''
class A {
  const A();
}
class B {
  final a;
  const B(num p) : a = p == const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
    verify([source]);
  }

  test_constEvalTypeBoolNumString_notEqual() async {
    Source source = addSource(r'''
class A {
  const A();
}
class B {
  final a;
  const B(String p) : a = p != const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL_NUM_STRING]);
    verify([source]);
  }

  test_constEvalTypeInt_binary() async {
    await _check_constEvalTypeInt_withParameter_binary("p ^ ''");
    await _check_constEvalTypeInt_withParameter_binary("p & ''");
    await _check_constEvalTypeInt_withParameter_binary("p | ''");
    await _check_constEvalTypeInt_withParameter_binary("p >> ''");
    await _check_constEvalTypeInt_withParameter_binary("p << ''");
  }

  test_constEvalTypeNum_binary() async {
    await _check_constEvalTypeNum_withParameter_binary("p + ''");
    await _check_constEvalTypeNum_withParameter_binary("p - ''");
    await _check_constEvalTypeNum_withParameter_binary("p * ''");
    await _check_constEvalTypeNum_withParameter_binary("p / ''");
    await _check_constEvalTypeNum_withParameter_binary("p ~/ ''");
    await _check_constEvalTypeNum_withParameter_binary("p > ''");
    await _check_constEvalTypeNum_withParameter_binary("p < ''");
    await _check_constEvalTypeNum_withParameter_binary("p >= ''");
    await _check_constEvalTypeNum_withParameter_binary("p <= ''");
    await _check_constEvalTypeNum_withParameter_binary("p % ''");
  }

  test_constFormalParameter_fieldFormalParameter() async {
    Source source = addSource(r'''
class A {
  var x;
  A(const this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }

  test_constFormalParameter_simpleFormalParameter() async {
    Source source = addSource("f(const x) {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_FORMAL_PARAMETER]);
    verify([source]);
  }

  test_constInitializedWithNonConstValue() async {
    Source source = addSource(r'''
f(p) {
  const C = p;
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  test_constInitializedWithNonConstValue_finalField() async {
    // Regression test for bug #25526 which previously
    // caused two errors to be reported.
    Source source = addSource(r'''
class Foo {
  final field = [];
  foo([int x = field]) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_constInitializedWithNonConstValue_missingConstInListLiteral() async {
    Source source = addSource("const List L = [0];");
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  test_constInitializedWithNonConstValue_missingConstInMapLiteral() async {
    Source source = addSource("const Map M = {'a' : 0};");
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE]);
    verify([source]);
  }

  test_constInitializedWithNonConstValueFromDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V;'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_constInitializedWithNonConstValueFromDeferredClass_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
const B = a.V + 1;'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_constInstanceField() async {
    Source source = addSource(r'''
class C {
  const int f = 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_INSTANCE_FIELD]);
    verify([source]);
  }

  test_constMapKeyTypeImplementsEquals_direct() async {
    Source source = addSource(r'''
class A {
  const A();
  operator ==(other) => false;
}
main() {
  const {const A() : 0};
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_constMapKeyTypeImplementsEquals_dynamic() async {
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
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_constMapKeyTypeImplementsEquals_factory() async {
    Source source = addSource(r'''
class A { const factory A() = B; }

class B implements A {
  const B();

  operator ==(o) => true;
}

main() {
  var m = const { const A(): 42 };
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_constMapKeyTypeImplementsEquals_super() async {
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
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_MAP_KEY_EXPRESSION_TYPE_IMPLEMENTS_EQUALS]);
    verify([source]);
  }

  test_constWithInvalidTypeParameters() async {
    Source source = addSource(r'''
class A {
  const A();
}
f() { return const A<A>(); }''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  test_constWithInvalidTypeParameters_tooFew() async {
    Source source = addSource(r'''
class A {}
class C<K, V> {
  const C();
}
f(p) {
  return const C<A>();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  test_constWithInvalidTypeParameters_tooMany() async {
    Source source = addSource(r'''
class A {}
class C<E> {
  const C();
}
f(p) {
  return const C<A, A>();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_WITH_INVALID_TYPE_PARAMETERS]);
    verify([source]);
  }

  test_constWithNonConst() async {
    Source source = addSource(r'''
class T {
  T(a, b, {c, d}) {}
}
f() { return const T(0, 1, c: 2, d: 3); }''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_WITH_NON_CONST]);
    verify([source]);
  }

  test_constWithNonConst_with() async {
    Source source = addSource(r'''
class B {
  const B();
}
class C = B with M;
class M {}
const x = const C();
main() {
  print(x);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_WITH_NON_CONST]);
    verify([source]);
  }

  test_constWithNonConstantArgument_annotation() async {
    Source source = addSource(r'''
class A {
  const A(int p);
}
var v = 42;
@A(v)
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT]);
    verify([source]);
  }

  test_constWithNonConstantArgument_instanceCreation() async {
    Source source = addSource(r'''
class A {
  const A(a);
}
f(p) { return const A(p); }''');
    // TODO(paulberry): the error INVALID_CONSTAT is redundant and ought to be
    // suppressed.
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT,
      CompileTimeErrorCode.INVALID_CONSTANT
    ]);
    verify([source]);
  }

  test_constWithNonType() async {
    Source source = addSource(r'''
int A;
f() {
  return const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source]);
  }

  test_constWithNonType_fromLibrary() async {
    Source source1 = addNamedSource("/lib.dart", "");
    Source source2 = addNamedSource("/lib2.dart", r'''
import 'lib.dart' as lib;
void f() {
  const lib.A();
}''');
    await computeAnalysisResult(source1);
    await computeAnalysisResult(source2);
    assertErrors(source2, [CompileTimeErrorCode.CONST_WITH_NON_TYPE]);
    verify([source1]);
  }

  test_constWithTypeParameters_direct() async {
    Source source = addSource(r'''
class A<T> {
  static const V = const A<T>();
  const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
      StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC
    ]);
    verify([source]);
  }

  test_constWithTypeParameters_indirect() async {
    Source source = addSource(r'''
class A<T> {
  static const V = const A<List<T>>();
  const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_WITH_TYPE_PARAMETERS,
      StaticWarningCode.TYPE_PARAMETER_REFERENCED_BY_STATIC
    ]);
    verify([source]);
  }

  test_constWithUndefinedConstructor() async {
    Source source = addSource(r'''
class A {
  const A();
}
f() {
  return const A.noSuchConstructor();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR]);
    // no verify(), 'noSuchConstructor' is not resolved
  }

  test_constWithUndefinedConstructorDefault() async {
    Source source = addSource(r'''
class A {
  const A.name();
}
f() {
  return const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.CONST_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT]);
    verify([source]);
  }

  test_defaultValueInFunctionTypeAlias() async {
    Source source = addSource("typedef F([x = 0]);");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE_ALIAS]);
    verify([source]);
  }

  test_defaultValueInFunctionTypedParameter_named() async {
    Source source = addSource("f(g({p: null})) {}");
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER]);
    verify([source]);
  }

  test_defaultValueInFunctionTypedParameter_optional() async {
    Source source = addSource("f(g([p = null])) {}");
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPED_PARAMETER]);
    verify([source]);
  }

  test_defaultValueInRedirectingFactoryConstructor() async {
    Source source = addSource(r'''
class A {
  factory A([int x = 0]) = B;
}

class B implements A {
  B([int x = 1]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR
    ]);
    verify([source]);
  }

  test_deferredImportWithInvalidUri() async {
    Source source = addSource(r'''
import '[invalid uri]' deferred as p;
main() {
  p.loadLibrary();
}''');
    await computeAnalysisResult(source);
    if (enableNewAnalysisDriver) {
      assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
    } else {
      assertErrors(source, [
        CompileTimeErrorCode.URI_DOES_NOT_EXIST,
        StaticWarningCode.UNDEFINED_IDENTIFIER
      ]);
    }
  }

  test_duplicateConstructorName_named() async {
    Source source = addSource(r'''
class A {
  A.a() {}
  A.a() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME,
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_NAME
    ]);
    verify([source]);
  }

  test_duplicateConstructorName_unnamed() async {
    Source source = addSource(r'''
class A {
  A() {}
  A() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT,
      CompileTimeErrorCode.DUPLICATE_CONSTRUCTOR_DEFAULT
    ]);
    verify([source]);
  }

  test_duplicateDefinition_acrossLibraries() async {
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
    await computeAnalysisResult(librarySource);
    await computeAnalysisResult(sourceA);
    await computeAnalysisResult(sourceB);
    assertNoErrors(librarySource);
    assertErrors(sourceB, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA, sourceB]);
  }

  test_duplicateDefinition_catch() async {
    Source source = addSource(r'''
main() {
  try {} catch (e, e) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_classMembers_fields() async {
    Source source = addSource(r'''
class A {
  int a;
  int a;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_classMembers_fields_oneStatic() async {
    Source source = addSource(r'''
class A {
  int x;
  static int x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_classMembers_methods() async {
    Source source = addSource(r'''
class A {
  m() {}
  m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_inPart() async {
    Source librarySource = addNamedSource("/lib.dart", r'''
library test;
part 'a.dart';
class A {}''');
    Source sourceA = addNamedSource("/a.dart", r'''
part of test;
class A {}''');
    await computeAnalysisResult(librarySource);
    await computeAnalysisResult(sourceA);
    assertNoErrors(librarySource);
    assertErrors(sourceA, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([librarySource, sourceA]);
  }

  test_duplicateDefinition_locals_inCase() async {
    Source source = addSource(r'''
main() {
  switch(1) {
    case 1:
      var a;
      var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_locals_inFunctionBlock() async {
    Source source = addSource(r'''
main() {
  int m = 0;
  m(a) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_locals_inIf() async {
    Source source = addSource(r'''
main(int p) {
  if (p != 0) {
    var a;
    var a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_locals_inMethodBlock() async {
    Source source = addSource(r'''
class A {
  m() {
    int a;
    int a;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_parameters_inConstructor() async {
    Source source = addSource(r'''
class A {
  int a;
  A(int a, this.a);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_parameters_inFunctionTypeAlias() async {
    Source source = addSource(r'''
typedef F(int a, double a);
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_parameters_inLocalFunction() async {
    Source source = addSource(r'''
main() {
  f(int a, double a) {
  };
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_parameters_inMethod() async {
    Source source = addSource(r'''
class A {
  m(int a, double a) {
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_parameters_inTopLevelFunction() async {
    Source source = addSource(r'''
f(int a, double a) {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinition_typeParameters() async {
    Source source = addSource(r'''
class A<T, T> {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_duplicateDefinitionInheritance_instanceGetter_staticGetter() async {
    Source source = addSource(r'''
class A {
  int get x => 0;
}
class B extends A {
  static int get x => 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  test_duplicateDefinitionInheritance_instanceGetterAbstract_staticGetter() async {
    Source source = addSource(r'''
abstract class A {
  int get x;
}
class B extends A {
  static int get x => 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  test_duplicateDefinitionInheritance_instanceMethod_staticMethod() async {
    Source source = addSource(r'''
class A {
  x() {}
}
class B extends A {
  static x() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  test_duplicateDefinitionInheritance_instanceMethodAbstract_staticMethod() async {
    Source source = addSource(r'''
abstract class A {
  x();
}
abstract class B extends A {
  static x() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  test_duplicateDefinitionInheritance_instanceSetter_staticSetter() async {
    Source source = addSource(r'''
class A {
  set x(value) {}
}
class B extends A {
  static set x(value) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  test_duplicateDefinitionInheritance_instanceSetterAbstract_staticSetter() async {
    Source source = addSource(r'''
abstract class A {
  set x(value);
}
class B extends A {
  static set x(value) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.DUPLICATE_DEFINITION_INHERITANCE]);
    verify([source]);
  }

  test_duplicateNamedArgument() async {
    Source source = addSource(r'''
f({a, b}) {}
main() {
  f(a: 1, a: 2);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT]);
    verify([source]);
  }

  test_duplicatePart_sameSource() async {
    addNamedSource('/part.dart', 'part of lib;');
    Source source = addSource(r'''
library lib;
part 'part.dart';
part 'foo/../part.dart';
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_PART]);
    verify([source]);
  }

  test_duplicatePart_sameUri() async {
    addNamedSource('/part.dart', 'part of lib;');
    Source source = addSource(r'''
library lib;
part 'part.dart';
part 'part.dart';
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_PART]);
    verify([source]);
  }

  test_exportInternalLibrary() async {
    Source source = addSource("export 'dart:_interceptors';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXPORT_INTERNAL_LIBRARY]);
    verify([source]);
  }

  test_exportOfNonLibrary() async {
    Source source = addSource(r'''
library L;
export 'lib1.dart';''');
    addNamedSource("/lib1.dart", "part of lib;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXPORT_OF_NON_LIBRARY]);
    verify([source]);
  }

  test_extendsDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B extends a.A {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS
    ]);
  }

  test_extendsDeferredClass_classTypeAlias() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class M {}
class C = a.A with M;'''
    ], <ErrorCode>[
      CompileTimeErrorCode.EXTENDS_DEFERRED_CLASS
    ]);
  }

  test_extendsDisallowedClass_class_bool() async {
    Source source = addSource("class A extends bool {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
    verify([source]);
  }

  test_extendsDisallowedClass_class_double() async {
    Source source = addSource("class A extends double {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_class_int() async {
    Source source = addSource("class A extends int {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
    verify([source]);
  }

  test_extendsDisallowedClass_class_Null() async {
    Source source = addSource("class A extends Null {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
    verify([source]);
  }

  test_extendsDisallowedClass_class_num() async {
    Source source = addSource("class A extends num {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_class_String() async {
    Source source = addSource("class A extends String {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS,
      CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT
    ]);
    verify([source]);
  }

  test_extendsDisallowedClass_classTypeAlias_bool() async {
    Source source = addSource(r'''
class M {}
class C = bool with M;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_classTypeAlias_double() async {
    Source source = addSource(r'''
class M {}
class C = double with M;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_classTypeAlias_int() async {
    Source source = addSource(r'''
class M {}
class C = int with M;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_classTypeAlias_Null() async {
    Source source = addSource(r'''
class M {}
class C = Null with M;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_classTypeAlias_num() async {
    Source source = addSource(r'''
class M {}
class C = num with M;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsDisallowedClass_classTypeAlias_String() async {
    Source source = addSource(r'''
class M {}
class C = String with M;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_extendsEnum() async {
    Source source = addSource(r'''
enum E { ONE }
class A extends E {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_ENUM]);
    verify([source]);
  }

  test_extendsNonClass_class() async {
    Source source = addSource(r'''
int A;
class B extends A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_NON_CLASS]);
    verify([source]);
  }

  test_extendsNonClass_dynamic() async {
    Source source = addSource("class B extends dynamic {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTENDS_NON_CLASS]);
    verify([source]);
  }

  test_extraPositionalArguments_const() async {
    Source source = addSource(r'''
class A {
  const A();
}
main() {
  const A(0);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  test_extraPositionalArguments_const_super() async {
    Source source = addSource(r'''
class A {
  const A();
}
class B extends A {
  const B() : super(0);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS]);
    verify([source]);
  }

  test_extraPositionalArgumentsCouldBeNamed_const() async {
    Source source = addSource(r'''
class A {
  const A({int x});
}
main() {
  const A(0);
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED]);
    verify([source]);
  }

  test_extraPositionalArgumentsCouldBeNamed_const_super() async {
    Source source = addSource(r'''
class A {
  const A({int x});
}
class B extends A {
  const B() : super(0);
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS_COULD_BE_NAMED]);
    verify([source]);
  }

  test_fieldFormalParameter_assignedInInitializer() async {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) : x = 3 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }

  test_fieldInitializedByMultipleInitializers() async {
    Source source = addSource(r'''
class A {
  int x;
  A() : x = 0, x = 1 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS]);
    verify([source]);
  }

  test_fieldInitializedByMultipleInitializers_multipleInits() async {
    Source source = addSource(r'''
class A {
  int x;
  A() : x = 0, x = 1, x = 2 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS
    ]);
    verify([source]);
  }

  test_fieldInitializedByMultipleInitializers_multipleNames() async {
    Source source = addSource(r'''
class A {
  int x;
  int y;
  A() : x = 0, x = 1, y = 0, y = 1 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS,
      CompileTimeErrorCode.FIELD_INITIALIZED_BY_MULTIPLE_INITIALIZERS
    ]);
    verify([source]);
  }

  test_fieldInitializedInParameterAndInitializer() async {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) : x = 1 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }

  test_fieldInitializerFactoryConstructor() async {
    Source source = addSource(r'''
class A {
  int x;
  factory A(this.x) => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.FIELD_INITIALIZER_FACTORY_CONSTRUCTOR]);
    verify([source]);
  }

  test_fieldInitializerOutsideConstructor() async {
    // TODO(brianwilkerson) Fix the duplicate error messages.
    Source source = addSource(r'''
class A {
  int x;
  m(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      ParserErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR,
      CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR
    ]);
    verify([source]);
  }

  test_fieldInitializerOutsideConstructor_defaultParameter() async {
    Source source = addSource(r'''
class A {
  int x;
  m([this.x]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }

  test_fieldInitializerOutsideConstructor_inFunctionTypeParameter() async {
    Source source = addSource(r'''
class A {
  int x;
  A(int p(this.x));
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.FIELD_INITIALIZER_OUTSIDE_CONSTRUCTOR]);
    verify([source]);
  }

  test_fieldInitializerRedirectingConstructor_afterRedirection() async {
    Source source = addSource(r'''
class A {
  int x;
  A.named() {}
  A() : this.named(), x = 42;
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  test_fieldInitializerRedirectingConstructor_beforeRedirection() async {
    Source source = addSource(r'''
class A {
  int x;
  A.named() {}
  A() : x = 42, this.named();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  test_fieldInitializingFormalRedirectingConstructor() async {
    Source source = addSource(r'''
class A {
  int x;
  A.named() {}
  A(this.x) : this.named();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZER_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  test_finalInitializedMultipleTimes_initializers() async {
    Source source = addSource(r'''
class A {
  final x;
  A() : x = 0, x = 0 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
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
  test_finalInitializedMultipleTimes_initializingFormal_initializer() async {
    Source source = addSource(r'''
class A {
  final x;
  A(this.x) : x = 0 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.FIELD_INITIALIZED_IN_PARAMETER_AND_INITIALIZER]);
    verify([source]);
  }

  test_finalInitializedMultipleTimes_initializingFormals() async {
    Source source = addSource(r'''
class A {
  final x;
  A(this.x, this.x) {}
}''');
    // TODO(brianwilkerson) There should only be one error here.
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.DUPLICATE_DEFINITION,
      CompileTimeErrorCode.FINAL_INITIALIZED_MULTIPLE_TIMES
    ]);
    verify([source]);
  }

  test_finalNotInitialized_instanceField_const_static() async {
    Source source = addSource(r'''
class A {
  static const F;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
    verify([source]);
  }

  test_finalNotInitialized_library_const() async {
    Source source = addSource("const F;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
    verify([source]);
  }

  test_finalNotInitialized_local_const() async {
    Source source = addSource(r'''
f() {
  const int x;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_NOT_INITIALIZED]);
    verify([source]);
  }

  test_fromEnvironment_bool_badArgs() async {
    Source source = addSource(r'''
var b1 = const bool.fromEnvironment(1);
var b2 = const bool.fromEnvironment('x', defaultValue: 1);''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_fromEnvironment_bool_badDefault_whenDefined() async {
    // The type of the defaultValue needs to be correct even when the default
    // value isn't used (because the variable is defined in the environment).
    if (enableNewAnalysisDriver) {
      driver.declaredVariables.define("x", "true");
    } else {
      analysisContext2.declaredVariables.define("x", "true");
    }
    Source source =
        addSource("var b = const bool.fromEnvironment('x', defaultValue: 1);");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_genericFunctionTypedParameter() async {
    // Once dartbug.com/28515 is fixed, this syntax should no longer generate an
    // error.
    // TODO(paulberry): When dartbug.com/28515 is fixed, convert this into a
    // NonErrorResolverTest.
    Source source = addSource('void g(T f<T>(T x)) {}');
    await computeAnalysisResult(source);
    var expectedErrorCodes = <ErrorCode>[
      CompileTimeErrorCode.GENERIC_FUNCTION_TYPED_PARAM_UNSUPPORTED
    ];
    if (enableNewAnalysisDriver) {
      // Due to dartbug.com/28515, some additional errors appear when using the
      // new analysis driver.
      expectedErrorCodes.addAll([
        StaticWarningCode.UNDEFINED_CLASS,
        StaticWarningCode.UNDEFINED_CLASS
      ]);
    }
    assertErrors(source, expectedErrorCodes);
    verify([source]);
  }

  test_getterAndMethodWithSameName() async {
    Source source = addSource(r'''
class A {
  x(y) {}
  get x => 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.GETTER_AND_METHOD_WITH_SAME_NAME]);
    verify([source]);
  }

  test_implementsDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B implements a.A {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS
    ]);
  }

  test_implementsDeferredClass_classTypeAlias() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B {}
class M {}
class C = B with M implements a.A;'''
    ], <ErrorCode>[
      CompileTimeErrorCode.IMPLEMENTS_DEFERRED_CLASS
    ]);
  }

  test_implementsDisallowedClass_class_bool() async {
    Source source = addSource("class A implements bool {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_class_double() async {
    Source source = addSource("class A implements double {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_class_int() async {
    Source source = addSource("class A implements int {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_class_Null() async {
    Source source = addSource("class A implements Null {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_class_num() async {
    Source source = addSource("class A implements num {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_class_String() async {
    Source source = addSource("class A implements String {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_class_String_num() async {
    Source source = addSource("class A implements String, num {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS
    ]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_bool() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements bool;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_double() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements double;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_int() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements int;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_Null() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements Null;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_num() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements num;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_String() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements String;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_implementsDisallowedClass_classTypeAlias_String_num() async {
    Source source = addSource(r'''
class A {}
class M {}
class C = A with M implements String, num;''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS,
      CompileTimeErrorCode.IMPLEMENTS_DISALLOWED_CLASS
    ]);
    verify([source]);
  }

  test_implementsDynamic() async {
    Source source = addSource("class A implements dynamic {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_DYNAMIC]);
    verify([source]);
  }

  test_implementsEnum() async {
    Source source = addSource(r'''
enum E { ONE }
class A implements E {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_ENUM]);
    verify([source]);
  }

  test_implementsNonClass_class() async {
    Source source = addSource(r'''
int A;
class B implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }

  test_implementsNonClass_typeAlias() async {
    Source source = addSource(r'''
class A {}
class M {}
int B;
class C = A with M implements B;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_NON_CLASS]);
    verify([source]);
  }

  test_implementsRepeated() async {
    Source source = addSource(r'''
class A {}
class B implements A, A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_REPEATED]);
    verify([source]);
  }

  test_implementsRepeated_3times() async {
    Source source = addSource(r'''
class A {} class C{}
class B implements A, A, A, A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      CompileTimeErrorCode.IMPLEMENTS_REPEATED,
      CompileTimeErrorCode.IMPLEMENTS_REPEATED
    ]);
    verify([source]);
  }

  test_implementsSuperClass() async {
    Source source = addSource(r'''
class A {}
class B extends A implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
    verify([source]);
  }

  test_implementsSuperClass_Object() async {
    Source source = addSource("class A implements Object {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
    verify([source]);
  }

  test_implementsSuperClass_Object_typeAlias() async {
    Source source = addSource(r'''
class M {}
class A = Object with M implements Object;
    ''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
    verify([source]);
  }

  test_implementsSuperClass_typeAlias() async {
    Source source = addSource(r'''
class A {}
class M {}
class B = A with M implements A;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPLEMENTS_SUPER_CLASS]);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_field() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f;
  var f;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_field2() async {
    Source source = addSource(r'''
class A {
  final x = 0;
  final y = x;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_invocation() async {
    Source source = addSource(r'''
class A {
  var v;
  A() : v = f();
  f() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_invocationInStatic() async {
    Source source = addSource(r'''
class A {
  static var F = m();
  m() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_redirectingConstructorInvocation() async {
    Source source = addSource(r'''
class A {
  A(p) {}
  A.named() : this(f);
  var f;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_implicitThisReferenceInInitializer_superConstructorInvocation() async {
    Source source = addSource(r'''
class A {
  A(p) {}
}
class B extends A {
  B() : super(f);
  var f;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_importInternalLibrary() async {
    Source source = addSource("import 'dart:_interceptors';");
    // Note, in these error cases we may generate an UNUSED_IMPORT hint, while
    // we could prevent the hint from being generated by testing the import
    // directive for the error, this is such a minor corner case that we don't
    // think we should add the additional computation time to figure out such
    // cases.
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.IMPORT_INTERNAL_LIBRARY, HintCode.UNUSED_IMPORT]);
    verify([source]);
  }

  test_importOfNonLibrary() async {
    Source source = addSource(r'''
library lib;
import 'part.dart';
A a;''');
    addNamedSource("/part.dart", r'''
part of lib;
class A{}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.IMPORT_OF_NON_LIBRARY]);
    verify([source]);
  }

  test_inconsistentCaseExpressionTypes() async {
    Source source = addSource(r'''
f(var p) {
  switch (p) {
    case 1:
      break;
    case 'a':
      break;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES]);
    verify([source]);
  }

  test_inconsistentCaseExpressionTypes_dynamic() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES
    ]);
    verify([source]);
  }

  test_inconsistentCaseExpressionTypes_repeated() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES,
      CompileTimeErrorCode.INCONSISTENT_CASE_EXPRESSION_TYPES
    ]);
    verify([source]);
  }

  test_initializerForNonExistent_const() async {
    // Check that the absence of a matching field doesn't cause a
    // crash during constant evaluation.
    Source source = addSource(r'''
class A {
  const A() : x = 'foo';
}
A a = const A();''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD]);
  }

  test_initializerForNonExistent_initializer() async {
    Source source = addSource(r'''
class A {
  A() : x = 0 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD]);
  }

  test_initializerForStaticField() async {
    Source source = addSource(r'''
class A {
  static int x;
  A() : x = 0 {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INITIALIZER_FOR_STATIC_FIELD]);
    verify([source]);
  }

  test_initializingFormalForNonExistentField() async {
    Source source = addSource(r'''
class A {
  A(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  test_initializingFormalForNonExistentField_notInEnclosingClass() async {
    Source source = addSource(r'''
class A {
int x;
}
class B extends A {
  B(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  test_initializingFormalForNonExistentField_optional() async {
    Source source = addSource(r'''
class A {
  A([this.x]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  test_initializingFormalForNonExistentField_synthetic() async {
    Source source = addSource(r'''
class A {
  int get x => 1;
  A(this.x) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_NON_EXISTENT_FIELD]);
    verify([source]);
  }

  test_initializingFormalForStaticField() async {
    Source source = addSource(r'''
class A {
  static int x;
  A([this.x]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INITIALIZING_FORMAL_FOR_STATIC_FIELD]);
    verify([source]);
  }

  test_instanceMemberAccessFromFactory_named() async {
    Source source = addSource(r'''
class A {
  m() {}
  A();
  factory A.make() {
    m();
    return new A();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY]);
    verify([source]);
  }

  test_instanceMemberAccessFromFactory_unnamed() async {
    Source source = addSource(r'''
class A {
  m() {}
  A._();
  factory A() {
    m();
    return new A._();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_FACTORY]);
    verify([source]);
  }

  test_instanceMemberAccessFromStatic_field() async {
    Source source = addSource(r'''
class A {
  int f;
  static foo() {
    f;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
    verify([source]);
  }

  test_instanceMemberAccessFromStatic_getter() async {
    Source source = addSource(r'''
class A {
  get g => null;
  static foo() {
    g;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
    verify([source]);
  }

  test_instanceMemberAccessFromStatic_method() async {
    Source source = addSource(r'''
class A {
  m() {}
  static foo() {
    m();
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INSTANCE_MEMBER_ACCESS_FROM_STATIC]);
    verify([source]);
  }

  test_instantiateEnum_const() async {
    Source source = addSource(r'''
enum E { ONE }
E e(String name) {
  return const E();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INSTANTIATE_ENUM]);
    verify([source]);
  }

  test_instantiateEnum_new() async {
    Source source = addSource(r'''
enum E { ONE }
E e(String name) {
  return new E();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INSTANTIATE_ENUM]);
    verify([source]);
  }

  test_invalidAnnotation_getter() async {
    Source source = addSource(r'''
get V => 0;
@V
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_importWithPrefix_getter() async {
    addNamedSource("/lib.dart", r'''
library lib;
get V => 0;''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.V
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_importWithPrefix_notConstantVariable() async {
    addNamedSource("/lib.dart", r'''
library lib;
final V = 0;''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.V
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_importWithPrefix_notVariableOrConstructorInvocation() async {
    addNamedSource("/lib.dart", r'''
library lib;
typedef V();''');
    Source source = addSource(r'''
import 'lib.dart' as p;
@p.V
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_notConstantVariable() async {
    Source source = addSource(r'''
final V = 0;
@V
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_notVariableOrConstructorInvocation() async {
    Source source = addSource(r'''
typedef V();
@V
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_staticMethodReference() async {
    Source source = addSource(r'''
class A {
  static f() {}
}
@A.f
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
    verify([source]);
  }

  test_invalidAnnotation_unresolved_identifier() async {
    Source source = addSource(r'''
@unresolved
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_unresolved_invocation() async {
    Source source = addSource(r'''
@Unresolved()
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_unresolved_prefixedIdentifier() async {
    Source source = addSource(r'''
import 'dart:math' as p;
@p.unresolved
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotation_useLibraryScope() async {
    Source source = addSource(r'''
@foo
class A {
  static const foo = null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_ANNOTATION]);
  }

  test_invalidAnnotationFromDeferredLibrary() async {
    // See test_invalidAnnotation_notConstantVariable
    await resolveWithErrors(<String>[
      r'''
library lib1;
class V { const V(); }
const v = const V();''',
      r'''
library root;
import 'lib1.dart' deferred as a;
@a.v main () {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary_constructor() async {
    // See test_invalidAnnotation_notConstantVariable
    await resolveWithErrors(<String>[
      r'''
library lib1;
class C { const C(); }''',
      r'''
library root;
import 'lib1.dart' deferred as a;
@a.C() main () {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_invalidAnnotationFromDeferredLibrary_namedConstructor() async {
    // See test_invalidAnnotation_notConstantVariable
    await resolveWithErrors(<String>[
      r'''
library lib1;
class C { const C.name(); }''',
      r'''
library root;
import 'lib1.dart' deferred as a;
@a.C.name() main () {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.INVALID_ANNOTATION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_invalidConstructorName_notEnclosingClassName_defined() async {
    Source source = addSource(r'''
class A {
  B() : super();
}
class B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
    // no verify() call, "B" is not resolved
  }

  test_invalidConstructorName_notEnclosingClassName_undefined() async {
    Source source = addSource(r'''
class A {
  B() : super();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME]);
    // no verify() call, "B" is not resolved
  }

  test_invalidFactoryNameNotAClass_notClassName() async {
    Source source = addSource(r'''
int B;
class A {
  factory B() => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
    verify([source]);
  }

  test_invalidFactoryNameNotAClass_notEnclosingClassName() async {
    Source source = addSource(r'''
class A {
  factory B() => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS]);
    // no verify() call, "B" is not resolved
  }

  test_invalidModifierOnConstructor_async() async {
    Source source = addSource(r'''
class A {
  A() async {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
    verify([source]);
  }

  test_invalidModifierOnConstructor_asyncStar() async {
    Source source = addSource(r'''
class A {
  A() async* {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
    verify([source]);
  }

  test_invalidModifierOnConstructor_syncStar() async {
    Source source = addSource(r'''
class A {
  A() sync* {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_CONSTRUCTOR]);
    verify([source]);
  }

  test_invalidModifierOnSetter_member_async() async {
    Source source = addSource(r'''
class A {
  set x(v) async {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  test_invalidModifierOnSetter_member_asyncStar() async {
    Source source = addSource(r'''
class A {
  set x(v) async* {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  test_invalidModifierOnSetter_member_syncStar() async {
    Source source = addSource(r'''
class A {
  set x(v) sync* {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  test_invalidModifierOnSetter_topLevel_async() async {
    Source source = addSource("set x(v) async {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  test_invalidModifierOnSetter_topLevel_asyncStar() async {
    Source source = addSource("set x(v) async* {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  test_invalidModifierOnSetter_topLevel_syncStar() async {
    Source source = addSource("set x(v) sync* {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_MODIFIER_ON_SETTER]);
    verify([source]);
  }

  test_invalidReferenceToThis_factoryConstructor() async {
    Source source = addSource(r'''
class A {
  factory A() { return this; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_instanceVariableInitializer_inConstructor() async {
    Source source = addSource(r'''
class A {
  var f;
  A() : f = this;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_instanceVariableInitializer_inDeclaration() async {
    Source source = addSource(r'''
class A {
  var f = this;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_staticMethod() async {
    Source source = addSource(r'''
class A {
  static m() { return this; }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_staticVariableInitializer() async {
    Source source = addSource(r'''
class A {
  static A f = this;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_superInitializer() async {
    Source source = addSource(r'''
class A {
  A(var x) {}
}
class B extends A {
  B() : super(this);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_topLevelFunction() async {
    Source source = addSource("f() { return this; }");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidReferenceToThis_variableInitializer() async {
    Source source = addSource("int x = this;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS]);
    verify([source]);
  }

  test_invalidTypeArgumentInConstList() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <E>[];
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_LIST]);
    verify([source]);
  }

  test_invalidTypeArgumentInConstMap() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <String, E>{};
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
    verify([source]);
  }

  test_invalidUri_export() async {
    Source source = addSource("export 'ht:';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_URI]);
  }

  test_invalidUri_import() async {
    Source source = addSource("import 'ht:';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_URI]);
  }

  test_invalidUri_part() async {
    Source source = addSource(r'''
library lib;
part 'ht:';''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.INVALID_URI]);
  }

  test_isInConstInstanceCreation_restored() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  test_isInInstanceVariableInitializer_restored() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER]);
    verify([source]);
  }

  test_labelInOuterScope() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE]);
    // We cannot verify resolution with unresolvable labels
  }

  test_labelUndefined_break() async {
    Source source = addSource(r'''
f() {
  x: while (true) {
    break y;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.LABEL_UNDEFINED]);
    // We cannot verify resolution with undefined labels
  }

  test_labelUndefined_continue() async {
    Source source = addSource(r'''
f() {
  x: while (true) {
    continue y;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.LABEL_UNDEFINED]);
    // We cannot verify resolution with undefined labels
  }

  test_length_of_erroneous_constant() async {
    // Attempting to compute the length of constant that couldn't be evaluated
    // (due to an error) should not crash the analyzer (see dartbug.com/23383)
    Source source = addSource("const int i = (1 ? 'alpha' : 'beta').length;");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE,
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_CONDITION
    ]);
    verify([source]);
  }

  test_memberWithClassName_field() async {
    Source source = addSource(r'''
class A {
  int A = 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }

  test_memberWithClassName_field2() async {
    Source source = addSource(r'''
class A {
  int z, A, b = 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }

  test_memberWithClassName_getter() async {
    Source source = addSource(r'''
class A {
  get A => 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MEMBER_WITH_CLASS_NAME]);
    verify([source]);
  }

  test_memberWithClassName_method() async {
    // no test because indistinguishable from constructor
  }

  test_methodAndGetterWithSameName() async {
    Source source = addSource(r'''
class A {
  get x => 0;
  x(y) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.METHOD_AND_GETTER_WITH_SAME_NAME]);
    verify([source]);
  }

  test_mixinDeclaresConstructor_classDeclaration() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  test_mixinDeclaresConstructor_typeAlias() async {
    Source source = addSource(r'''
class A {
  A() {}
}
class B = Object with A;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_DECLARES_CONSTRUCTOR]);
    verify([source]);
  }

  test_mixinDeferredClass() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B extends Object with a.A {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.MIXIN_DEFERRED_CLASS
    ]);
  }

  test_mixinDeferredClass_classTypeAlias() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
class A {}''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class B {}
class C = B with a.A;'''
    ], <ErrorCode>[
      CompileTimeErrorCode.MIXIN_DEFERRED_CLASS
    ]);
  }

  test_mixinHasNoConstructors_mixinApp() async {
    Source source = addSource(r'''
class B {
  B({x});
}
class M {}
class C = B with M;
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  test_mixinHasNoConstructors_mixinClass() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  test_mixinHasNoConstructors_mixinClass_explicitSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  test_mixinHasNoConstructors_mixinClass_implicitSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  test_mixinHasNoConstructors_mixinClass_namedSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS]);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_extends() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_classDeclaration_with() async {
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C extends Object with B {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_typeAlias_extends() async {
    Source source = addSource(r'''
class A {}
class B extends A {}
class C = Object with B;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  test_mixinInheritsFromNotObject_typeAlias_with() async {
    Source source = addSource(r'''
class A {}
class B extends Object with A {}
class C = Object with B;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_class_bool() async {
    Source source = addSource("class A extends Object with bool {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_class_double() async {
    Source source = addSource("class A extends Object with double {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_class_int() async {
    Source source = addSource("class A extends Object with int {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_class_Null() async {
    Source source = addSource("class A extends Object with Null {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_class_num() async {
    Source source = addSource("class A extends Object with num {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_class_String() async {
    Source source = addSource("class A extends Object with String {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_bool() async {
    Source source = addSource(r'''
class A {}
class C = A with bool;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_double() async {
    Source source = addSource(r'''
class A {}
class C = A with double;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_int() async {
    Source source = addSource(r'''
class A {}
class C = A with int;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_Null() async {
    Source source = addSource(r'''
class A {}
class C = A with Null;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_num() async {
    Source source = addSource(r'''
class A {}
class C = A with num;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_String() async {
    Source source = addSource(r'''
class A {}
class C = A with String;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS]);
    verify([source]);
  }

  test_mixinOfDisallowedClass_classTypeAlias_String_num() async {
    Source source = addSource(r'''
class A {}
class C = A with String, num;''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS,
      CompileTimeErrorCode.MIXIN_OF_DISALLOWED_CLASS
    ]);
    verify([source]);
  }

  test_mixinOfEnum() async {
    Source source = addSource(r'''
enum E { ONE }
class A extends Object with E {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_ENUM]);
    verify([source]);
  }

  test_mixinOfNonClass_class() async {
    Source source = addSource(r'''
int A;
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }

  test_mixinOfNonClass_typeAlias() async {
    Source source = addSource(r'''
class A {}
int B;
class C = A with B;''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_OF_NON_CLASS]);
    verify([source]);
  }

  test_mixinReferencesSuper() async {
    Source source = addSource(r'''
class A {
  toString() => super.toString();
}
class B extends Object with A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MIXIN_REFERENCES_SUPER]);
    verify([source]);
  }

  test_mixinWithNonClassSuperclass_class() async {
    Source source = addSource(r'''
int A;
class B {}
class C extends A with B {}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }

  test_mixinWithNonClassSuperclass_typeAlias() async {
    Source source = addSource(r'''
int A;
class B {}
class C = A with B;''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.MIXIN_WITH_NON_CLASS_SUPERCLASS]);
    verify([source]);
  }

  test_multipleRedirectingConstructorInvocations() async {
    Source source = addSource(r'''
class A {
  A() : this.a(), this.b();
  A.a() {}
  A.b() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.MULTIPLE_REDIRECTING_CONSTRUCTOR_INVOCATIONS]);
    verify([source]);
  }

  test_multipleSuperInitializers() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() : super(), super() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.MULTIPLE_SUPER_INITIALIZERS]);
    verify([source]);
  }

  test_nativeClauseInNonSDKCode() async {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    Source source = addSource("class A native 'string' {}");
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.NATIVE_CLAUSE_IN_NON_SDK_CODE]);
    verify([source]);
  }

  test_nativeFunctionBodyInNonSDKCode_function() async {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    Source source = addSource("int m(a) native 'string';");
    await computeAnalysisResult(source);
    assertErrors(
        source, [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }

  test_nativeFunctionBodyInNonSDKCode_method() async {
    // TODO(jwren) Move this test somewhere else: This test verifies a parser
    // error code is generated through the ErrorVerifier, it is not a
    // CompileTimeErrorCode.
    Source source = addSource(r'''
class A{
  static int m(a) native 'string';
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [ParserErrorCode.NATIVE_FUNCTION_BODY_IN_NON_SDK_CODE]);
    verify([source]);
  }

  test_noAnnotationConstructorArguments() async {
    Source source = addSource(r'''
class A {
  const A();
}
@A
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit() async {
    Source source = addSource(r'''
class A {
  A(p);
}
class B extends A {
  B() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit_MixinAppWithDirectSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit_mixinAppWithNamedParam() async {
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
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit_MixinAppWithNamedSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    // Don't verify since call to super.named() can't be resolved.
  }

  test_noDefaultSuperConstructorExplicit_mixinAppWithOptionalParam() async {
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
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit_MixinWithDirectSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit_mixinWithNamedParam() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorExplicit_MixinWithNamedSuperCall() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    // Don't verify since call to super.named() can't be resolved.
  }

  test_noDefaultSuperConstructorExplicit_mixinWithOptionalParam() async {
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
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_EXPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorImplicit_mixinAppWithNamedParam() async {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorImplicit_mixinAppWithOptionalParam() async {
    Source source = addSource(r'''
class M {}
class B {
  B([x]);
  B.named(); // To avoid MIXIN_HAS_NO_CONSTRUCTORS
}
class Mixed = B with M;
class C extends Mixed {}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorImplicit_mixinWithNamedParam() async {
    Source source = addSource(r'''
class M {}
class B {
  B({x});
  B.other();
}
class C extends B with M {}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorImplicit_mixinWithOptionalParam() async {
    Source source = addSource(r'''
class M {}
class B {
  B([x]);
  B.other();
}
class C extends B with M {}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorImplicit_superHasParameters() async {
    Source source = addSource(r'''
class A {
  A(p);
}
class B extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  test_noDefaultSuperConstructorImplicit_superOnlyNamed() async {
    Source source = addSource(r'''
class A { A.named() {} }
class B extends A {}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NO_DEFAULT_SUPER_CONSTRUCTOR_IMPLICIT]);
    verify([source]);
  }

  test_nonConstantAnnotationConstructor_named() async {
    Source source = addSource(r'''
class A {
  A.fromInt() {}
}
@A.fromInt()
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR]);
    verify([source]);
  }

  test_nonConstantAnnotationConstructor_unnamed() async {
    Source source = addSource(r'''
class A {
  A() {}
}
@A()
main() {
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_ANNOTATION_CONSTRUCTOR]);
    verify([source]);
  }

  test_nonConstantDefaultValue_function_named() async {
    Source source = addSource(r'''
int y;
f({x : y}) {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_nonConstantDefaultValue_function_positional() async {
    Source source = addSource(r'''
int y;
f([x = y]) {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_nonConstantDefaultValue_inConstructor_named() async {
    Source source = addSource(r'''
class A {
  int y;
  A({x : y}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_nonConstantDefaultValue_inConstructor_positional() async {
    Source source = addSource(r'''
class A {
  int y;
  A([x = y]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_nonConstantDefaultValue_method_named() async {
    Source source = addSource(r'''
class A {
  int y;
  m({x : y}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_nonConstantDefaultValue_method_positional() async {
    Source source = addSource(r'''
class A {
  int y;
  m([x = y]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE]);
    verify([source]);
  }

  test_nonConstantDefaultValueFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V}) {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstantDefaultValueFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const V = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f({x : a.V + 1}) {}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_DEFAULT_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstCaseExpression() async {
    Source source = addSource(r'''
f(int p, int q) {
  switch (p) {
    case 3 + q:
      break;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION]);
    verify([source]);
  }

  test_nonConstCaseExpressionFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c:
      break;
  }
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstCaseExpressionFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
main (int p) {
  switch (p) {
    case a.c + 1:
      break;
  }
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_CASE_EXPRESSION_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstListElement() async {
    Source source = addSource(r'''
f(a) {
  return const [a];
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT]);
    verify([source]);
  }

  test_nonConstListElementFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const [a.c];
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstListElementFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const [a.c + 1];
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstMapAsExpressionStatement_begin() async {
    Source source = addSource(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }

  test_nonConstMapAsExpressionStatement_only() async {
    Source source = addSource(r'''
f() {
  {'a' : 0, 'b' : 1};
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }

  test_nonConstMapKey() async {
    Source source = addSource(r'''
f(a) {
  return const {a : 0};
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_MAP_KEY]);
    verify([source]);
  }

  test_nonConstMapKeyFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c : 0};
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstMapKeyFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c + 1 : 0};
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_MAP_KEY_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstMapValue() async {
    Source source = addSource(r'''
f(a) {
  return const {'a' : a};
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE]);
    verify([source]);
  }

  test_nonConstMapValueFromDeferredLibrary() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {'a' : a.c};
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstMapValueFromDeferredLibrary_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {'a' : a.c + 1};
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode.NON_CONSTANT_MAP_VALUE_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstValueInInitializer_assert_condition() async {
    resetWith(
        options: new AnalysisOptionsImpl()..enableAssertInitializer = true);
    Source source = addSource(r'''
class A {
  const A(int i) : assert(i.isNegative);
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  test_nonConstValueInInitializer_assert_message() async {
    resetWith(
        options: new AnalysisOptionsImpl()..enableAssertInitializer = true);
    Source source = addSource(r'''
class A {
  const A(int i) : assert(i < 0, 'isNegative = ${i.isNegative}');
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_notBool_left() async {
    Source source = addSource(r'''
class A {
  final bool a;
  const A(String p) : a = p && true;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_OPERAND
    ]);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_notBool_right() async {
    Source source = addSource(r'''
class A {
  final bool a;
  const A(String p) : a = true && p;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_OPERAND
    ]);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_notInt() async {
    Source source = addSource(r'''
class A {
  final int a;
  const A(String p) : a = 5 & p;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_INT,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_nonConstValueInInitializer_binary_notNum() async {
    Source source = addSource(r'''
class A {
  final int a;
  const A(String p) : a = 5 + p;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_NUM,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
  }

  test_nonConstValueInInitializer_field() async {
    Source source = addSource(r'''
class A {
  static int C;
  final int a;
  const A() : a = C;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  test_nonConstValueInInitializer_instanceCreation() async {
    Source source = addSource(r'''
class A {
  A();
}
class B {
  const B() : a = new A();
  final a;
}
var b = const B();''');
    // TODO(scheglov): the error CONST_EVAL_THROWS_EXCEPTION is redundant and
    // ought to be suppressed. Or not?
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION
    ]);
    verify([source]);
  }

  test_nonConstValueInInitializer_instanceCreation_inDifferentFile() async {
    resetWith(options: new AnalysisOptionsImpl()..strongMode = true);
    Source source = addNamedSource('/a.dart', r'''
import 'b.dart';
const v = const MyClass();
''');
    addNamedSource('/b.dart', r'''
class MyClass {
  const MyClass([p = foo]);
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
  }

  test_nonConstValueInInitializer_redirecting() async {
    Source source = addSource(r'''
class A {
  static var C;
  const A.named(p);
  const A() : this.named(C);
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
  }

  test_nonConstValueInInitializer_super() async {
    Source source = addSource(r'''
class A {
  const A(p);
}
class B extends A {
  static var C;
  const B() : super(C);
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.NON_CONSTANT_VALUE_IN_INITIALIZER]);
    verify([source]);
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
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_field_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  final int x;
  const A() : x = a.c + 1;
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_redirecting() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A.named(p);
  const A() : this.named(a.c);
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonConstValueInInitializerFromDeferredLibrary_super() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
class A {
  const A(p);
}
class B extends A {
  const B() : super(a.c);
}'''
    ], <ErrorCode>[
      CompileTimeErrorCode
          .NON_CONSTANT_VALUE_IN_INITIALIZER_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_nonGenerativeConstructor_explicit() async {
    Source source = addSource(r'''
class A {
  factory A.named() => null;
}
class B extends A {
  B() : super.named();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  test_nonGenerativeConstructor_implicit() async {
    Source source = addSource(r'''
class A {
  factory A() => null;
}
class B extends A {
  B();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  test_nonGenerativeConstructor_implicit2() async {
    Source source = addSource(r'''
class A {
  factory A() => null;
}
class B extends A {
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  test_notEnoughRequiredArguments_const() async {
    Source source = addSource(r'''
class A {
  const A(int p);
}
main() {
  const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  test_notEnoughRequiredArguments_const_super() async {
    Source source = addSource(r'''
class A {
  const A(int p);
}
class B extends A {
  const B() : super();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS]);
    verify([source]);
  }

  test_optionalParameterInOperator_named() async {
    Source source = addSource(r'''
class A {
  operator +({p}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }

  test_optionalParameterInOperator_positional() async {
    Source source = addSource(r'''
class A {
  operator +([p]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.OPTIONAL_PARAMETER_IN_OPERATOR]);
    verify([source]);
  }

  test_partOfNonPart() async {
    Source source = addSource(r'''
library l1;
part 'l2.dart';''');
    addNamedSource("/l2.dart", "library l2;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.PART_OF_NON_PART]);
    verify([source]);
  }

  test_partOfNonPart_self() async {
    Source source = addSource(r'''
library lib;
part 'test.dart';''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.PART_OF_NON_PART]);
    verify([source]);
  }

  test_prefix_assignment_compound_in_method() async {
    addNamedSource('/lib.dart', 'library lib;');
    Source source = addSource('''
import 'lib.dart' as p;
class C {
  f() {
    p += 1;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_assignment_compound_not_in_method() async {
    addNamedSource('/lib.dart', 'library lib;');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_assignment_in_method() async {
    addNamedSource('/lib.dart', 'library lib;');
    Source source = addSource('''
import 'lib.dart' as p;
class C {
  f() {
    p = 1;
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_assignment_not_in_method() async {
    addNamedSource('/lib.dart', 'library lib;');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_conditionalPropertyAccess_call() async {
    addNamedSource('/lib.dart', '''
library lib;
g() {}
''');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p?.g();
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_conditionalPropertyAccess_call_loadLibrary() async {
    addNamedSource('/lib.dart', '''
library lib;
''');
    Source source = addSource('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary();
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_conditionalPropertyAccess_get() async {
    addNamedSource('/lib.dart', '''
library lib;
var x;
''');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  return p?.x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_conditionalPropertyAccess_get_loadLibrary() async {
    addNamedSource('/lib.dart', '''
library lib;
''');
    Source source = addSource('''
import 'lib.dart' deferred as p;
f() {
  return p?.loadLibrary;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_conditionalPropertyAccess_set() async {
    addNamedSource('/lib.dart', '''
library lib;
var x;
''');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p?.x = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_conditionalPropertyAccess_set_loadLibrary() async {
    addNamedSource('/lib.dart', '''
library lib;
''');
    Source source = addSource('''
import 'lib.dart' deferred as p;
f() {
  p?.loadLibrary = null;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_unqualified_invocation_in_method() async {
    addNamedSource('/lib.dart', 'librarylib;');
    Source source = addSource('''
import 'lib.dart' as p;
class C {
  f() {
    p();
  }
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefix_unqualified_invocation_not_in_method() async {
    addNamedSource('/lib.dart', 'librarylib;');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p();
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefixCollidesWithTopLevelMembers_functionTypeAlias() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
typedef p();
p.A a;''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  test_prefixCollidesWithTopLevelMembers_topLevelFunction() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
p() {}
p.A a;''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  test_prefixCollidesWithTopLevelMembers_topLevelVariable() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
var p = null;
p.A a;''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  test_prefixCollidesWithTopLevelMembers_type() async {
    addNamedSource("/lib.dart", r'''
library lib;
class A{}''');
    Source source = addSource(r'''
import 'lib.dart' as p;
class p {}
p.A a;''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_COLLIDES_WITH_TOP_LEVEL_MEMBER]);
    verify([source]);
  }

  test_prefixNotFollowedByDot() async {
    addNamedSource('/lib.dart', 'library lib;');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  return p;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefixNotFollowedByDot_compoundAssignment() async {
    addNamedSource('/lib.dart', 'library lib;');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p += 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
  }

  test_prefixNotFollowedByDot_conditionalMethodInvocation() async {
    addNamedSource('/lib.dart', '''
library lib;
g() {}
''');
    Source source = addSource('''
import 'lib.dart' as p;
f() {
  p?.g();
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT]);
    verify([source]);
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
    Source source = addSource("f({var _p}) {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }

  test_privateOptionalParameter_fieldFormal() async {
    Source source = addSource(r'''
class A {
  var _p;
  A({this._p: 0});
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }

  test_privateOptionalParameter_withDefaultValue() async {
    Source source = addSource("f({_p : 0}) {}");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.PRIVATE_OPTIONAL_PARAMETER]);
    verify([source]);
  }

  test_recursiveCompileTimeConstant() async {
    Source source = addSource(r'''
class A {
  const A();
  final m = const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }

  test_recursiveCompileTimeConstant_cycle() async {
    Source source = addSource(r'''
const x = y + 1;
const y = x + 1;''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT,
      CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT
    ]);
    verify([source]);
  }

  test_recursiveCompileTimeConstant_initializer_after_toplevel_var() async {
    Source source = addSource('''
const y = const C();
class C {
  const C() : x = y;
  final x;
}
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }

  test_recursiveCompileTimeConstant_singleVariable() async {
    Source source = addSource(r'''
const x = x;
''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT]);
    verify([source]);
  }

  test_recursiveConstructorRedirect() async {
    Source source = addSource(r'''
class A {
  A.a() : this.b();
  A.b() : this.a();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT
    ]);
    verify([source]);
  }

  test_recursiveConstructorRedirect_directSelfReference() async {
    Source source = addSource(r'''
class A {
  A() : this();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.RECURSIVE_CONSTRUCTOR_REDIRECT]);
    verify([source]);
  }

  test_recursiveFactoryRedirect() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveFactoryRedirect_directSelfReference() async {
    Source source = addSource(r'''
class A {
  factory A() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
    verify([source]);
  }

  test_recursiveFactoryRedirect_diverging() async {
    // Analysis should terminate even though the redirections don't reach a
    // fixed point.  (C<int> redirects to C<C<int>>, then to C<C<C<int>>>, and
    // so on).
    Source source = addSource('''
class C<T> {
  const factory C() = C<C<T>>;
}
main() {
  const C<int>();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT]);
    verify([source]);
  }

  test_recursiveFactoryRedirect_generic() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveFactoryRedirect_named() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  /**
   * "A" references "C" which has cycle with "B". But we should not report problem for "A" - it is
   * not the part of a cycle.
   */
  test_recursiveFactoryRedirect_outsideCycle() async {
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
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_extends() async {
    Source source = addSource(r'''
class A extends B {}
class B extends A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_extends_implements() async {
    Source source = addSource(r'''
class A extends B {}
class B implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_implements() async {
    Source source = addSource(r'''
class A implements B {}
class B implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_mixin() async {
    Source source = addSource(r'''
class M1 = Object with M2;
class M2 = Object with M1;''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    Source source = addSource('''
class C = D with M;
class D = C with M;
class M {}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_tail() async {
    Source source = addSource(r'''
abstract class A implements A {}
class B implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_tail2() async {
    Source source = addSource(r'''
abstract class A implements B {}
abstract class B implements A {}
class C implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritance_tail3() async {
    Source source = addSource(r'''
abstract class A implements B {}
abstract class B implements C {}
abstract class C implements A {}
class D implements A {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE,
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritanceBaseCaseExtends() async {
    Source source = addSource("class A extends A {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritanceBaseCaseExtends_abstract() async {
    Source source = addSource(r'''
class C extends C {
  var bar = 0;
  m();
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_EXTENDS,
      StaticWarningCode.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER,
      StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_ONE
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritanceBaseCaseImplements() async {
    Source source = addSource("class A implements A {}");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritanceBaseCaseImplements_typeAlias() async {
    Source source = addSource(r'''
class A {}
class M {}
class B = A with M implements B;''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_IMPLEMENTS
    ]);
    verify([source]);
  }

  test_recursiveInterfaceInheritanceBaseCaseWith() async {
    Source source = addSource("class M = Object with M;");
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.RECURSIVE_INTERFACE_INHERITANCE_BASE_CASE_WITH]);
    verify([source]);
  }

  test_redirectGenerativeToMissingConstructor() async {
    Source source = addSource(r'''
class A {
  A() : this.noSuchConstructor();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_MISSING_CONSTRUCTOR]);
  }

  test_redirectGenerativeToNonGenerativeConstructor() async {
    Source source = addSource(r'''
class A {
  A() : this.x();
  factory A.x() => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.REDIRECT_GENERATIVE_TO_NON_GENERATIVE_CONSTRUCTOR
    ]);
    verify([source]);
  }

  test_redirectToMissingConstructor_named() async {
    Source source = addSource(r'''
class A implements B{
  A() {}
}
class B {
  const factory B() = A.name;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  test_redirectToMissingConstructor_unnamed() async {
    Source source = addSource(r'''
class A implements B{
  A.name() {}
}
class B {
  const factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.REDIRECT_TO_MISSING_CONSTRUCTOR]);
  }

  test_redirectToNonClass_notAType() async {
    Source source = addSource(r'''
int A;
class B {
  const factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  test_redirectToNonClass_undefinedIdentifier() async {
    Source source = addSource(r'''
class B {
  const factory B() = A;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REDIRECT_TO_NON_CLASS]);
    verify([source]);
  }

  test_redirectToNonConstConstructor() async {
    Source source = addSource(r'''
class A {
  A.a() {}
  const factory A.b() = A.a;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.REDIRECT_TO_NON_CONST_CONSTRUCTOR]);
    verify([source]);
  }

  test_referencedBeforeDeclaration_hideInBlock_function() async {
    Source source = addSource(r'''
var v = 1;
main() {
  print(v);
  v() {}
}
print(x) {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_hideInBlock_local() async {
    Source source = addSource(r'''
var v = 1;
main() {
  print(v);
  var v = 2;
}
print(x) {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_hideInBlock_subBlock() async {
    Source source = addSource(r'''
var v = 1;
main() {
  {
    print(v);
  }
  var v = 2;
}
print(x) {}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_inInitializer_closure() async {
    Source source = addSource(r'''
main() {
  var v = () => v;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_inInitializer_directly() async {
    Source source = addSource(r'''
main() {
  var v = v;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_type_localFunction() async {
    Source source = addSource(r'''
void testTypeRef() {
  String s = '';
  int String(int x) => x + 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_referencedBeforeDeclaration_type_localVariable() async {
    Source source = addSource(r'''
void testTypeRef() {
  String s = '';
  var String = '';
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION]);
  }

  test_rethrowOutsideCatch() async {
    Source source = addSource(r'''
f() {
  rethrow;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.RETHROW_OUTSIDE_CATCH]);
    verify([source]);
  }

  test_returnInGenerativeConstructor() async {
    Source source = addSource(r'''
class A {
  A() { return 0; }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  test_returnInGenerativeConstructor_expressionFunctionBody() async {
    Source source = addSource(r'''
class A {
  A() => null;
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.RETURN_IN_GENERATIVE_CONSTRUCTOR]);
    verify([source]);
  }

  test_returnInGenerator_asyncStar() async {
    Source source = addSource(r'''
f() async* {
  return 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.RETURN_IN_GENERATOR]);
    verify([source]);
  }

  test_returnInGenerator_syncStar() async {
    Source source = addSource(r'''
f() sync* {
  return 0;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.RETURN_IN_GENERATOR]);
    verify([source]);
  }

  test_sharedDeferredPrefix() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
f1() {}''',
      r'''
library lib2;
f2() {}''',
      r'''
library root;
import 'lib1.dart' deferred as lib;
import 'lib2.dart' as lib;
main() { lib.f1(); lib.f2(); }'''
    ], <ErrorCode>[
      CompileTimeErrorCode.SHARED_DEFERRED_PREFIX
    ]);
  }

  test_superInInvalidContext_binaryExpression() async {
    Source source = addSource("var v = super + 0;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.v' is not resolved
  }

  test_superInInvalidContext_constructorFieldInitializer() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  var f;
  B() : f = super.m();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.m' is not resolved
  }

  test_superInInvalidContext_factoryConstructor() async {
    Source source = addSource(r'''
class A {
  m() {}
}
class B extends A {
  factory B() {
    super.m();
    return null;
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.m' is not resolved
  }

  test_superInInvalidContext_instanceVariableInitializer() async {
    Source source = addSource(r'''
class A {
  var a;
}
class B extends A {
 var b = super.a;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.a' is not resolved
  }

  test_superInInvalidContext_staticMethod() async {
    Source source = addSource(r'''
class A {
  static m() {}
}
class B extends A {
  static n() { return super.m(); }
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.m' is not resolved
  }

  test_superInInvalidContext_staticVariableInitializer() async {
    Source source = addSource(r'''
class A {
  static int a = 0;
}
class B extends A {
  static int b = super.a;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.a' is not resolved
  }

  test_superInInvalidContext_topLevelFunction() async {
    Source source = addSource(r'''
f() {
  super.f();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.f' is not resolved
  }

  test_superInInvalidContext_topLevelVariableInitializer() async {
    Source source = addSource("var v = super.y;");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT]);
    // no verify(), 'super.y' is not resolved
  }

  test_superInRedirectingConstructor_redirectionSuper() async {
    Source source = addSource(r'''
class A {}
class B {
  B() : this.name(), super();
  B.name() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  test_superInRedirectingConstructor_superRedirection() async {
    Source source = addSource(r'''
class A {}
class B {
  B() : super(), this.name();
  B.name() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.SUPER_IN_REDIRECTING_CONSTRUCTOR]);
    verify([source]);
  }

  test_symbol_constructor_badArgs() async {
    Source source = addSource(r'''
var s1 = const Symbol('3');
var s2 = const Symbol(3);
var s3 = const Symbol();
var s4 = const Symbol('x', 'y');
var s5 = const Symbol('x', foo: 'x');''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS,
      CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS,
      CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER
    ]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_11987() async {
    Source source = addSource(r'''
typedef void F(List<G> l);
typedef void G(List<F> l);
main() {
  F foo(G g) => g;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
    ]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_19459() async {
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
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_parameterType_named() async {
    Source source = addSource("typedef A({A a});");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_parameterType_positional() async {
    Source source = addSource("typedef A([A a]);");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_parameterType_required() async {
    Source source = addSource("typedef A(A a);");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_parameterType_typeArgument() async {
    Source source = addSource("typedef A(List<A> a);");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_returnClass_withTypeAlias() async {
    // A typedef is allowed to indirectly reference itself via a class.
    Source source = addSource(r'''
typedef C A();
typedef A B();
class C {
  B a;
}''');
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_returnType() async {
    Source source = addSource("typedef A A();");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_returnType_indirect() async {
    Source source = addSource(r'''
typedef B A();
typedef A B();''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF,
      CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
    ]);
    verify([source]);
  }

  test_typeAliasCannotReferenceItself_typeVariableBounds() async {
    Source source = addSource("typedef A<T extends A>();");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF]);
    verify([source]);
  }

  test_typeArgumentNotMatchingBounds_const() async {
    Source source = addSource(r'''
class A {}
class B {}
class G<E extends A> {
  const G();
}
f() { return const G<B>(); }''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS]);
    verify([source]);
  }

  test_undefinedClass_const() async {
    Source source = addSource(r'''
f() {
  return const A();
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_explicit_named() async {
    Source source = addSource(r'''
class A {}
class B extends A {
  B() : super.named();
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER]);
    // no verify(), "super.named()" is not resolved
  }

  test_undefinedConstructorInInitializer_explicit_unnamed() async {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B extends A {
  B() : super();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_undefinedConstructorInInitializer_implicit() async {
    Source source = addSource(r'''
class A {
  A.named() {}
}
class B extends A {
  B();
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT]);
    verify([source]);
  }

  test_undefinedNamedParameter() async {
    Source source = addSource(r'''
class A {
  const A();
}
main() {
  const A(p: 0);
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER]);
    // no verify(), 'p' is not resolved
  }

  test_uriDoesNotExist_export() async {
    Source source = addSource("export 'unknown.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriDoesNotExist_import() async {
    Source source = addSource("import 'unknown.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriDoesNotExist_import_appears_after_deleting_target() async {
    Source test = addSource("import 'target.dart';");
    Source target = addNamedSource("/target.dart", "");
    await computeAnalysisResult(test);
    assertErrors(test, [HintCode.UNUSED_IMPORT]);

    // Remove the overlay in the same way as AnalysisServer.
    resourceProvider.deleteFile(target.fullName);
    if (enableNewAnalysisDriver) {
      driver.removeFile(target.fullName);
    } else {
      analysisContext2.setContents(target, null);
      ChangeSet changeSet = new ChangeSet()..removedSource(target);
      analysisContext2.applyChanges(changeSet);
    }

    await computeAnalysisResult(test);
    assertErrors(test, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriDoesNotExist_import_disappears_when_fixed() async {
    Source source = addSource("import 'target.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);

    String targetPath = resourceProvider.convertPath('/target.dart');
    if (enableNewAnalysisDriver) {
      // Add an overlay in the same way as AnalysisServer.
      fileContentOverlay[targetPath] = '';
      driver.changeFile(targetPath);
    } else {
      // Check that the file is represented as missing.
      Source target = analysisContext2.getSourcesWithFullName(targetPath).first;
      expect(analysisContext2.getModificationStamp(target), -1);

      // Add an overlay in the same way as AnalysisServer.
      analysisContext2
        ..setContents(target, "")
        ..handleContentsChanged(target, null, "", true);
    }

    // Make sure the error goes away.
    await computeAnalysisResult(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
  }

  test_uriDoesNotExist_part() async {
    Source source = addSource(r'''
library lib;
part 'unknown.dart';''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  test_uriWithInterpolation_constant() async {
    Source source = addSource("import 'stuff_\$platform.dart';");
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.URI_WITH_INTERPOLATION,
      StaticWarningCode.UNDEFINED_IDENTIFIER
    ]);
    // We cannot verify resolution with an unresolvable
    // URI: 'stuff_$platform.dart'
  }

  test_uriWithInterpolation_nonConstant() async {
    Source source = addSource(r'''
library lib;
part '${'a'}.dart';''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.URI_WITH_INTERPOLATION]);
    // We cannot verify resolution with an unresolvable URI: '${'a'}.dart'
  }

  test_wrongNumberOfParametersForOperator1() async {
    await _check_wrongNumberOfParametersForOperator1("<");
    await _check_wrongNumberOfParametersForOperator1(">");
    await _check_wrongNumberOfParametersForOperator1("<=");
    await _check_wrongNumberOfParametersForOperator1(">=");
    await _check_wrongNumberOfParametersForOperator1("+");
    await _check_wrongNumberOfParametersForOperator1("/");
    await _check_wrongNumberOfParametersForOperator1("~/");
    await _check_wrongNumberOfParametersForOperator1("*");
    await _check_wrongNumberOfParametersForOperator1("%");
    await _check_wrongNumberOfParametersForOperator1("|");
    await _check_wrongNumberOfParametersForOperator1("^");
    await _check_wrongNumberOfParametersForOperator1("&");
    await _check_wrongNumberOfParametersForOperator1("<<");
    await _check_wrongNumberOfParametersForOperator1(">>");
    await _check_wrongNumberOfParametersForOperator1("[]");
  }

  test_wrongNumberOfParametersForOperator_minus() async {
    Source source = addSource(r'''
class A {
  operator -(a, b) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(source,
        [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR_MINUS]);
    verify([source]);
    reset();
  }

  test_wrongNumberOfParametersForOperator_tilde() async {
    await _check_wrongNumberOfParametersForOperator("~", "a");
    await _check_wrongNumberOfParametersForOperator("~", "a, b");
  }

  test_wrongNumberOfParametersForSetter_function_named() async {
    Source source = addSource("set x({p}) {}");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_function_optional() async {
    Source source = addSource("set x([p]) {}");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_function_tooFew() async {
    Source source = addSource("set x() {}");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_function_tooMany() async {
    Source source = addSource("set x(a, b) {}");
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_method_named() async {
    Source source = addSource(r'''
class A {
  set x({p}) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_method_optional() async {
    Source source = addSource(r'''
class A {
  set x([p]) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_method_tooFew() async {
    Source source = addSource(r'''
class A {
  set x() {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_wrongNumberOfParametersForSetter_method_tooMany() async {
    Source source = addSource(r'''
class A {
  set x(a, b) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_SETTER]);
    verify([source]);
  }

  test_yield_used_as_identifier_in_async_method() async {
    Source source = addSource('''
f() async {
  var yield = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_yield_used_as_identifier_in_async_star_method() async {
    Source source = addSource('''
f() async* {
  var yield = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  test_yield_used_as_identifier_in_sync_star_method() async {
    Source source = addSource('''
f() sync* {
  var yield = 1;
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [ParserErrorCode.ASYNC_KEYWORD_USED_AS_IDENTIFIER]);
    verify([source]);
  }

  Future<Null> _check_constEvalThrowsException_binary_null(
      String expr, bool resolved) async {
    Source source = addSource("const C = $expr;");
    if (resolved) {
      await computeAnalysisResult(source);
      assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
      verify([source]);
    } else {
      await computeAnalysisResult(source);
      assertErrors(source, [CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION]);
      // no verify(), 'null x' is not resolved
    }
    reset();
  }

  Future<Null> _check_constEvalTypeBool_withParameter_binary(
      String expr) async {
    Source source = addSource('''
class A {
  final a;
  const A(bool p) : a = $expr;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_BOOL,
      StaticTypeWarningCode.NON_BOOL_OPERAND
    ]);
    verify([source]);
    reset();
  }

  Future<Null> _check_constEvalTypeInt_withParameter_binary(String expr) async {
    Source source = addSource('''
class A {
  final a;
  const A(int p) : a = $expr;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_INT,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
    reset();
  }

  Future<Null> _check_constEvalTypeNum_withParameter_binary(String expr) async {
    Source source = addSource('''
class A {
  final a;
  const A(num p) : a = $expr;
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [
      CompileTimeErrorCode.CONST_EVAL_TYPE_NUM,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
    verify([source]);
    reset();
  }

  Future<Null> _check_wrongNumberOfParametersForOperator(
      String name, String parameters) async {
    Source source = addSource('''
class A {
  operator $name($parameters) {}
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR]);
    verify([source]);
    reset();
  }

  Future<Null> _check_wrongNumberOfParametersForOperator1(String name) async {
    await _check_wrongNumberOfParametersForOperator(name, "");
    await _check_wrongNumberOfParametersForOperator(name, "a, b");
  }

  Future<Null> _privateCollisionInMixinApplicationTest(String testCode) async {
    resetWith(options: new AnalysisOptionsImpl()..strongMode = true);
    addNamedSource('/lib1.dart', '''
class A {
  int _x;
}

class B {
  int _x;
}
''');
    Source source = addSource(testCode);
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.PRIVATE_COLLISION_IN_MIXIN_APPLICATION]);
    verify([source]);
  }
}
