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
    defineReflectiveTests(ControlFlowCollectionsTest);
  });
}

@reflectiveTest
class CompileTimeErrorCodeTest extends CompileTimeErrorCodeTestBase {
  @override
  @failingTest
  test_constEvalThrowsException() {
    return super.test_constEvalThrowsException();
  }
}

@reflectiveTest
class ControlFlowCollectionsTest extends DriverResolutionTest {
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
