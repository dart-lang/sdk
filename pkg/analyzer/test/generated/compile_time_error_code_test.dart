// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
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
  test_defaultValueInFunctionTypeAlias_new_named() async {
    // This test used to fail with UI as code enabled. Test the fix here.
    await assertErrorsInCode('''
typedef F = int Function({Map<String, String> m: const {}});
''', [
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 47, 1),
    ]);
  }

  test_defaultValueInFunctionTypeAlias_new_named_ambiguous() async {
    // Test that the strong checker does not crash when given an ambiguous
    // set or map literal.
    await assertErrorsInCode('''
typedef F = int Function({Object m: const {1, 2: 3}});
''', [
      error(ParserErrorCode.DEFAULT_VALUE_IN_FUNCTION_TYPE, 34, 1),
      error(CompileTimeErrorCode.AMBIGUOUS_SET_OR_MAP_LITERAL_BOTH, 36, 15),
    ]);
  }
}

@reflectiveTest
class ControlFlowCollectionsTest extends DriverResolutionTest {
  test_awaitForIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
import 'dart:async';
f() async {
  Stream<String> stream;
  await for (int i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 75, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 80, 6),
    ]);
  }

  test_awaitForIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
import 'dart:async';
f() async {
  Stream<String> stream;
  int i;
  await for (i in stream) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 64, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 85, 6),
    ]);
  }

  test_awaitForIn_notStream() async {
    await assertErrorsInCode('''
f() async {
  await for (var i in true) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 29, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 34, 4),
    ]);
  }

  test_expectedOneListTypeArgument() async {
    await assertErrorsInCode(r'''
main() {
  <int, int>[];
}''', [
      error(StaticTypeWarningCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS, 11, 10),
    ]);
  }

  test_expectedOneSetTypeArgument() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{2, 3};
}''', [
      error(StaticTypeWarningCode.EXPECTED_ONE_SET_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_expectedTwoMapTypeArguments_three_ambiguous() async {
    // TODO(brianwilkerson) We probably need a new error code for "expected
    //  either one or two type arguments" to handle the ambiguous case.
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{};
}''', [
      error(StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_expectedTwoMapTypeArguments_three_map() async {
    await assertErrorsInCode(r'''
main() {
  <int, int, int>{1:2};
}''', [
      error(StaticTypeWarningCode.EXPECTED_TWO_MAP_TYPE_ARGUMENTS, 11, 15),
    ]);
  }

  test_forIn_declaredVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  for (int i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 22, 10),
    ]);
  }

  test_forIn_existingVariableWrongType() async {
    await assertErrorsInCode('''
f() {
  int i;
  for (i in <String>[]) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 27, 10),
    ]);
  }

  test_forIn_notIterable() async {
    await assertErrorsInCode('''
f() {
  for (var i in true) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_TYPE, 22, 4),
    ]);
  }

  test_forIn_typeBoundBad() async {
    await assertErrorsInCode('''
class Foo<T extends Iterable<int>> {
  void method(T iterable) {
    for (String i in iterable) {}
  }
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 81, 1),
      error(StaticTypeWarningCode.FOR_IN_OF_INVALID_ELEMENT_TYPE, 86, 8),
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

  test_generalizedVoid_useOfInForeachIterableError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  for (var v in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 35, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 40, 1),
    ]);
  }

  test_generalizedVoid_useOfVoidInForeachVariableError() async {
    await assertErrorsInCode(r'''
void main() {
  void x;
  var y;
  for (y in x) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 30, 1),
      error(StaticWarningCode.USE_OF_VOID_RESULT, 45, 1),
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

  test_invalidTypeArgumentInConstMap_key() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E, String>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_MAP, 39, 1),
    ]);
  }

  test_invalidTypeArgumentInConstMap_value() async {
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

  test_invalidTypeArgumentInConstSet_class() async {
    await assertErrorsInCode(r'''
class A<E> {
  m() {
    return const <E>{};
  }
}
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET, 39, 1),
    ]);
  }

  test_listElementTypeNotAssignable_const() async {
    await assertErrorsInCode('''
var v = const <String>[42];
''', [
      error(StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE, 23, 2),
    ]);
  }

  test_mapValueTypeNotAssignable_const() async {
    await assertErrorsInCode('''
var v = const <String, String>{'a' : 2};
''', [
      error(StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE, 37, 1),
    ]);
  }

  test_nonBoolCondition_for_declaration() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  for (int i = 0; 3;) {}
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 17, 1),
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 24, 1),
    ]);
  }

  test_nonBoolCondition_for_expression() async {
    // https://github.com/dart-lang/sdk/issues/24713
    await assertErrorsInCode(r'''
f() {
  int i;
  for (i = 0; 3;) {}
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 12, 1),
      error(StaticTypeWarningCode.NON_BOOL_CONDITION, 29, 1),
    ]);
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
    // TODO(danrubel) Fasta is not recovering well.
    // Ideally we would produce a single diagnostic:
    // CompileTimeErrorCode.NON_CONST_MAP_AS_EXPRESSION_STATEMENT
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

  test_setElementTypeNotAssignable_const() async {
    await assertErrorsInCode('''
var v = const <String>{42};
''', [
      error(StaticWarningCode.SET_ELEMENT_TYPE_NOT_ASSIGNABLE, 23, 2),
    ]);
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
''', [
      error(CompileTimeErrorCode.INVALID_TYPE_ARGUMENT_IN_CONST_SET, 39, 1),
    ]);
  }
}
