// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/driver_resolution.dart';
import 'compile_time_error_code.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompileTimeErrorCodeTest);
    defineReflectiveTests(CompileTimeErrorCodeTest_WithUIAsCode);
    defineReflectiveTests(ControlFlowCollectionsTest);
    defineReflectiveTests(InvalidTypeArgumentInConstSetTest);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest extends CompileTimeErrorCodeTestBase {
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
class CompileTimeErrorCodeTest_WithUIAsCode extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [
      EnableString.control_flow_collections,
      EnableString.spread_collections
    ];

  test_defaultValueInFunctionTypeAlias_new_named() async {
    // This test used to fail with UI as code enabled. Test the fix here.
    await assertErrorsInCode('''
typedef F = int Function({Map<String, String> m: const {}});
''', [
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE,
    ]);
  }

  test_defaultValueInFunctionTypeAlias_new_named_ambiguous() async {
    // Test that the strong checker does not crash when given an ambiguous
    // set or map literal.
    await assertErrorsInCode('''
typedef F = int Function({Object m: const {1, 2: 3}});
''', [
      ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE,
      CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH,
    ]);
  }
}

@reflectiveTest
class ControlFlowCollectionsTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..enabledExperiments = [EnableString.control_flow_collections];

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
    await assertErrorsInCode(r'''
f() {
  for (int i = 0, i = 0; i < 5;) {}
}
''', [CompileTimeErrorCode.DUPLICATE_DEFINITION]);
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

  test_generalizedVoid_useOfInForeachIterableError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  for (var v in x) {}
}
''', [StaticWarningCode.USE_OF_VOID_RESULT]);
  }

  test_generalizedVoid_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  var y;
  for (y in x) {}
}
''', [StaticWarningCode.USE_OF_VOID_RESULT]);
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

  test_invalidTypeArgumentInConstMap_key() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E, String>{};
  }
}
''', [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
  }

  test_invalidTypeArgumentInConstMap_value() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <String, E>{};
  }
}
''', [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP]);
  }

  test_invalidTypeArgumentInConstSet_class() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}
''', [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET]);
  }

  test_listElementTypeNotAssignable_const() async {
    await assertErrorsInCode('''
var v = const <String>[42];
''', [StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }

  test_mapValueTypeNotAssignable_const() async {
    await assertErrorsInCode('''
var v = const <String, String>{'a' : 2};
''', [StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
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
    // TODO(danrubel) Fasta is not recovering well.
    // Ideally we would produce a single diagnostic:
    // CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT
    await assertErrorsInCode(r'''
f() {
  {'a' : 0, 'b' : 1}.length;
}
''', [
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
  }

  test_nonConstMapAsExpressionStatement_only() async {
    // TODO(danrubel) Fasta is not recovering well.
    // Ideally we would produce a single diagnostic:
    // CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT
    await assertErrorsInCode(r'''
f() {
  {'a' : 0, 'b' : 1};
}
''', [
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
  }

  test_setElementTypeNotAssignable_const() async {
    await assertErrorsInCode('''
var v = const <String>{42};
''', [StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE]);
  }
}

@reflectiveTest
class InvalidTypeArgumentInConstSetTest extends DriverResolutionTest {
  test_class() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}
''', [CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET]);
  }
}
