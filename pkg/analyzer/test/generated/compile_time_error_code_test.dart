// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'compile_time_error_code.dart';
import 'resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest);
    defineReflectiveTests(ControlFlowCollectionsTest);
    defineReflectiveTests(InvalidTypeArgumentInConstSetTest);
    defineReflectiveTests(NonConstSetElementFromDeferredLibraryTest);
    defineReflectiveTests(NonConstSetElementTest);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest extends CompileTimeErrorCodeTestBase {
  @override
  bool get enableNewAnalysisDriver => true;

  @override
  @failingTest
  test_awaitInWrongContext_sync() {
    return super.test_awaitInWrongContext_sync();
  }

  @override
  @failingTest
  test_constEvalThrowsException() {
    return super.test_constEvalThrowsException();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_async() {
    return super.test_invalidIdentifierInAsync_async();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_await() {
    return super.test_invalidIdentifierInAsync_await();
  }

  @override
  @failingTest
  test_invalidIdentifierInAsync_yield() {
    return super.test_invalidIdentifierInAsync_yield();
  }

  @override
  @failingTest
  test_mixinOfNonClass() {
    return super.test_mixinOfNonClass();
  }

  @override
  @failingTest
  test_objectCannotExtendAnotherClass() {
    return super.test_objectCannotExtendAnotherClass();
  }

  @override
  @failingTest
  test_superInitializerInObject() {
    return super.test_superInitializerInObject();
  }

  @override
  @failingTest
  test_yieldEachInNonGenerator_async() {
    return super.test_yieldEachInNonGenerator_async();
  }

  @override
  @failingTest
  test_yieldEachInNonGenerator_sync() {
    return super.test_yieldEachInNonGenerator_sync();
  }

  @override
  @failingTest
  test_yieldInNonGenerator_async() {
    return super.test_yieldInNonGenerator_async();
  }

  @override
  @failingTest
  test_yieldInNonGenerator_sync() {
    return super.test_yieldInNonGenerator_sync();
  }
}

@reflectiveTest
class ControlFlowCollectionsTest extends ResolverTestCase {
  @override
  List<String> get enabledExperiments =>
      [EnableString.control_flow_collections];

  @override
  bool get enableNewAnalysisDriver => true;

  test_awaitForIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
import 'dart:async';
f() async {
  Stream<String> stream;
  await for (int i in stream) {}
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  test_awaitForIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
import 'dart:async';
f() async {
  Stream<String> stream;
  int i;
  await for (i in stream) {}
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  test_awaitForIn_notStream() async {
    await assertErrorsInCode('''
f() async {
  await for (var i in true) {}
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE]);
  }

  test_duplicateDefinition_for_initializers() async {
    Source source = addSource(r'''
f() {
  for (int i = 0, i = 0; i < 5;) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
    verify([source]);
  }

  test_expectedOneListTypeArgument() async {
    await assertErrorsInCode(r'''
main() {
  <int, int>[];
}''', [StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS]);
  }

  test_expectedOneSetTypeArgument() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{2, 3};
}''', [StaticTypeWarningCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS]);
  }

  test_expectedTwoMapTypeArguments_three_ambiguous() async {
    // TODO(brianwilkerson) We probably need a new error code for "expected
    //  either one or two type arguments" to handle the ambiguous case.
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{};
}''', [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS]);
  }

  test_expectedTwoMapTypeArguments_three_map() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{1:2};
}''', [StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS]);
  }

  test_forIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <String>[]) {}
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  test_forIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <String>[]) {}
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  test_forIn_notIterable() async {
    await assertErrorsInCode('''
f() {
  for (var i in true) {}
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE]);
  }

  test_forIn_typeBoundBad() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
  }
}
''', [StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE]);
  }

  test_forInWithConstVariable_forEach_identifier() async {
    Source source = addSource(r'''
f() {
  const x = 0;
  for (x in [0, 1, 2]) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE]);
    verify([source]);
  }

  test_forInWithConstVariable_forEach_loopVariable() async {
    Source source = addSource(r'''
f() {
  for (const x in [0, 1, 2]) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.FOR_IN_WITH_CONST_VARIABLE]);
    verify([source]);
  }

  test_generalizedVoid_useOfInForeachIterableError() async {
    Source source = addSource(r'''
void main() {
  void x;
  for (var v in x) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInForeachVariableError() async {
    Source source = addSource(r'''
void main() {
  void x;
  var y;
  for (y in x) {}
}
''');
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.USE_OF_VOID_RESULT]);
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

  test_invalidTypeArgumentInConstMap_key() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <E, String>{};
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
    verify([source]);
  }

  test_invalidTypeArgumentInConstMap_value() async {
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

  test_invalidTypeArgumentInConstSet_class() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET]);
    verify([source]);
  }

  test_listElementTypeNotAssignable_const() async {
    Source source = addSource("var v = const <String>[42];");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_mapKeyTypeNotAssignable_const() async {
    Source source = addSource("var v = const <String, int >{1 : 2};");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_mapValueTypeNotAssignable_const() async {
    Source source = addSource("var v = const <String, String>{'a' : 2};");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  test_nonBoolCondition_for_declaration() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (int i = 0; 3;) {}
}
''', [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  test_nonBoolCondition_for_expression() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  int i;
  for (i = 0; 3;) {}
}''', [StaticTypeWarningCode.NON_BOOL_CONDITION]);
  }

  test_nonConstMapAsExpressionStatement_begin() async {
    Source source = addSource(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}''');
    await computeAnalysisResult(source);
    // TODO(danrubel) Fasta is not recovering.
    assertErrors(source, [
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
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
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
//    assertErrors(
//        source, [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }

  test_nonConstMapAsExpressionStatement_only() async {
    Source source = addSource(r'''
f() {
  {'a' : 0, 'b' : 1};
}''');
    await computeAnalysisResult(source);
    // TODO(danrubel) Fasta is not recovering.
    assertErrors(source, [
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.UNEXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.EXPECTED_TOKEN,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER,
      ParserErrorCode.MISSING_IDENTIFIER
    ]);
//    assertErrors(
//        source, [CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT]);
    verify([source]);
  }

  test_setElementTypeNotAssignable_const() async {
    Source source = addSource("var v = const <String>{42};");
    await computeAnalysisResult(source);
    assertErrors(source, [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }
}

@reflectiveTest
class InvalidTypeArgumentInConstSetTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_class() async {
    Source source = addSource(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}''');
    await computeAnalysisResult(source);
    assertErrors(
        source, [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET]);
    verify([source]);
  }
}

@reflectiveTest
class NonConstSetElementFromDeferredLibraryTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_topLevelVariable_immediate() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c};
}'''
    ], [
      CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY
    ]);
  }

  test_topLevelVariable_nested() async {
    await resolveWithErrors(<String>[
      r'''
library lib1;
const int c = 1;''',
      r'''
library root;
import 'lib1.dart' deferred as a;
f() {
  return const {a.c + 1};
}'''
    ], [
      CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT_FROM_DEFERRED_LIBRARY
    ]);
  }
}

@reflectiveTest
class NonConstSetElementTest extends ResolverTestCase {
  @override
  bool get enableNewAnalysisDriver => true;

  test_parameter() async {
    Source source = addSource(r'''
f(a) {
  return const {a};
}''');
    await computeAnalysisResult(source);
    assertErrors(source, [CompileTimeErrorCode.NON_CONSTANT_SET_ELEMENT]);
    verify([source]);
  }
}
