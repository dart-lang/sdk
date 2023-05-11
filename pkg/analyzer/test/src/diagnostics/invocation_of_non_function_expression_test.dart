// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvocationOfNonFunctionExpressionTest);
  });
}

@reflectiveTest
class InvocationOfNonFunctionExpressionTest extends PubPackageResolutionTest {
  test_literal_int() async {
    await assertErrorsInCode(r'''
void f() {
  3(5);
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 13, 1),
    ]);

    final node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: IntegerLiteral
    literal: 3
    staticType: int
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 5
        parameter: <null>
        staticType: int
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_literal_null() async {
    noSoundNullSafety = false;
    await assertErrorsInCode(r'''
// @dart = 2.9
void f() {
  null();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 28, 4),
    ]);

    final node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: NullLiteral
    literal: null
    staticType: Null*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }

  test_type_Null() async {
    noSoundNullSafety = false;
    await assertErrorsInCode(r'''
// @dart = 2.9
void f(Null a) {
  a();
}
''', [
      error(CompileTimeErrorCode.INVOCATION_OF_NON_FUNCTION_EXPRESSION, 34, 1),
    ]);

    final node = findNode.singleFunctionExpressionInvocation;
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: a
    staticElement: self::@function::f::@parameter::a
    staticType: Null*
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }
}
