// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementCaseResolutionTest);
    defineReflectiveTests(IfStatementResolutionTest);
  });
}

@reflectiveTest
class IfStatementCaseResolutionTest extends PatternsResolutionTest {
  test_caseClause_rewrite() async {
    await assertNoErrorsInCode(r'''
void f(x, int Function() a) {
  if (x case const a()) {}
}
''');

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    pattern: ConstantPattern
      const: const
      expression: FunctionExpressionInvocation
        function: SimpleIdentifier
          token: a
          staticElement: self::@function::f::@parameter::a
          staticType: int Function()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        staticElement: <null>
        staticInvokeType: int Function()
        staticType: int
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_expression_rewrite() async {
    await assertNoErrorsInCode(r'''
void f(int Function() a) {
  if (a() case 42) {}
}
''');

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function()
    staticType: int
  caseClause: CaseClause
    caseKeyword: case
    pattern: ConstantPattern
      expression: IntegerLiteral
        literal: 42
        staticType: int
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }
}

@reflectiveTest
class IfStatementResolutionTest extends PubPackageResolutionTest {
  test_expression_rewrite() async {
    await assertNoErrorsInCode(r'''
void f(bool Function() a) {
  if (a()) {}
}
''');

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      staticElement: self::@function::f::@parameter::a
      staticType: bool Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: bool Function()
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }
}
