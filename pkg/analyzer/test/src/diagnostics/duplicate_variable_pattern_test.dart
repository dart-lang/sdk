// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateVariablePatternTest);
  });
}

@reflectiveTest
class DuplicateVariablePatternTest extends PubPackageResolutionTest {
  test_ifCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case var a && var a) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 42, 1,
          contextMessages: [message(testFile, 33, 1)]),
    ]);
    var node = findNode.singleIfStatement;
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: int
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalAndPattern
        leftOperand: DeclaredVariablePattern
          keyword: var
          name: a
          declaredElement: hasImplicitType a@33
            type: int
          matchedValueType: int
        operator: &&
        rightOperand: DeclaredVariablePattern
          keyword: var
          name: a
          declaredElement: hasImplicitType a@42
            type: int
          matchedValueType: int
        matchedValueType: int
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@33
          element: a@33
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_switchStatement() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var a && var a:
      a;
  }
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 53, 1,
          contextMessages: [message(testFile, 44, 1)]),
    ]);
    var node = findNode.singleSwitchPatternCase;
    assertResolvedNodeText(node, r'''
SwitchPatternCase
  keyword: case
  guardedPattern: GuardedPattern
    pattern: LogicalAndPattern
      leftOperand: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@44
          type: int
        matchedValueType: int
      operator: &&
      rightOperand: DeclaredVariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@53
          type: int
        matchedValueType: int
      matchedValueType: int
  colon: :
  statements
    ExpressionStatement
      expression: SimpleIdentifier
        token: a
        staticElement: a@44
        element: a@44
        staticType: int
      semicolon: ;
''');
  }

  test_variableDeclaration() async {
    await assertErrorsInCode(r'''
void f() {
  var [a, a] = [0, 1];
  a;
}
''', [
      error(CompileTimeErrorCode.DUPLICATE_VARIABLE_PATTERN, 21, 1,
          contextMessages: [message(testFile, 18, 1)]),
    ]);

    var node = findNode.singleBlock;
    assertResolvedNodeText(node, r'''
Block
  leftBracket: {
  statements
    PatternVariableDeclarationStatement
      declaration: PatternVariableDeclaration
        keyword: var
        pattern: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              name: a
              declaredElement: hasImplicitType a@18
                type: int
              matchedValueType: int
            DeclaredVariablePattern
              name: a
              declaredElement: hasImplicitType a@21
                type: int
              matchedValueType: int
          rightBracket: ]
          matchedValueType: List<int>
          requiredType: List<int>
        equals: =
        expression: ListLiteral
          leftBracket: [
          elements
            IntegerLiteral
              literal: 0
              staticType: int
            IntegerLiteral
              literal: 1
              staticType: int
          rightBracket: ]
          staticType: List<int>
        patternTypeSchema: List<_>
      semicolon: ;
    ExpressionStatement
      expression: SimpleIdentifier
        token: a
        staticElement: a@18
        element: a@18
        staticType: int
      semicolon: ;
  rightBracket: }
''');
  }
}
