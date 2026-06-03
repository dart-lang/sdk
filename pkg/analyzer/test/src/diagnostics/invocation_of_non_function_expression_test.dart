// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  3(5);
//^
// [diag.invocationOfNonFunctionExpression] The expression doesn't evaluate to a function, so it can't be invoked.
}
''');

    var node = result.findNode.singleFunctionExpressionInvocation;
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
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
  staticInvokeType: InvalidType
  staticType: InvalidType
''');
  }
}
