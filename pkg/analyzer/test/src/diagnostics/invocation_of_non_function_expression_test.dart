// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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

    var node = findNode.singleFunctionExpressionInvocation;
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
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }
}
