// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementResolutionTest);
  });
}

@reflectiveTest
class IfStatementResolutionTest extends PatternsResolutionTest {
  test_caseClause() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
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
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_consistent() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | [int a] when a > 0) {
    a;
  }
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
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: VariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@37
            type: int
        operator: |
        rightOperand: ListPattern
          leftBracket: [
          elements
            VariablePattern
              type: NamedType
                name: SimpleIdentifier
                  token: int
                  staticElement: dart:core::@class::int
                  staticType: null
                type: int
              name: a
              declaredElement: a@46
                type: int
          rightBracket: ]
          requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a[a@37, a@46]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a[a@37, a@46]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_notConsistent_differentFinality() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | [final int a] when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.NOT_CONSISTENT_VARIABLE_PATTERN, 52, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: VariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@37
            type: int
        operator: |
        rightOperand: ListPattern
          leftBracket: [
          elements
            VariablePattern
              keyword: final
              type: NamedType
                name: SimpleIdentifier
                  token: int
                  staticElement: dart:core::@class::int
                  staticType: null
                type: int
              name: a
              declaredElement: isFinal a@52
                type: int
          rightBracket: ]
          requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@37, a@52]
            staticType: dynamic
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: <null>
            staticType: int
          staticElement: <null>
          staticInvokeType: null
          staticType: dynamic
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@52]
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_notConsistent_differentType() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | [double a] when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.NOT_CONSISTENT_VARIABLE_PATTERN, 49, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: VariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@37
            type: int
        operator: |
        rightOperand: ListPattern
          leftBracket: [
          elements
            VariablePattern
              type: NamedType
                name: SimpleIdentifier
                  token: double
                  staticElement: dart:core::@class::double
                  staticType: null
                type: double
              name: a
              declaredElement: a@49
                type: double
          rightBracket: ]
          requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@37, a@49]
            staticType: dynamic
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: <null>
            staticType: int
          staticElement: <null>
          staticInvokeType: null
          staticType: dynamic
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@49]
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_1() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | 2 | 3 when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 41, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 45, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: BinaryPattern
          leftOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@37
              type: int
          operator: |
          rightOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 2
              staticType: int
        operator: |
        rightOperand: ConstantPattern
          expression: IntegerLiteral
            literal: 3
            staticType: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@37]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_12() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | int a | 3 when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 49, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: BinaryPattern
          leftOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@37
              type: int
          operator: |
          rightOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@45
              type: int
        operator: |
        rightOperand: ConstantPattern
          expression: IntegerLiteral
            literal: 3
            staticType: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@37, a@45]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@45]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_123() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | int a | int a when a > 0) {
    a;
  }
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
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: BinaryPattern
          leftOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@37
              type: int
          operator: |
          rightOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@45
              type: int
        operator: |
        rightOperand: VariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@53
            type: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a[a@37, a@45, a@53]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a[a@37, a@45, a@53]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_13() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a | 2 | int a when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 41, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: BinaryPattern
          leftOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@37
              type: int
          operator: |
          rightOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 2
              staticType: int
        operator: |
        rightOperand: VariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@49
            type: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@37, a@49]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@49]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_2() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case 1 | int a | 3 when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 33, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 45, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: BinaryPattern
          leftOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 1
              staticType: int
          operator: |
          rightOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@41
              type: int
        operator: |
        rightOperand: ConstantPattern
          expression: IntegerLiteral
            literal: 3
            staticType: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@41]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@41]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_23() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case 1 | int a | int a when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 33, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: BinaryPattern
        leftOperand: BinaryPattern
          leftOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 1
              staticType: int
          operator: |
          rightOperand: VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@41
              type: int
        operator: |
        rightOperand: VariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@49
            type: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@41, a@49]
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@41, a@49]
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_scope() async {
    // Each `guardedPattern` introduces a new case scope which is where the
    // variables defined by that case's pattern are bound.
    // There is no initializing expression for the variables in a case pattern,
    // but they are considered initialized after the entire case pattern,
    // before the guard expression if there is one. However, all pattern
    // variables are in scope in the entire pattern.
    await assertErrorsInCode(r'''
const a = 0;
void f(Object? x) {
  if (x case [int a, == a] when a > 0) {
    a;
  } else {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 57, 1,
          contextMessages: [message('/home/test/lib/test.dart', 51, 1)]),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ListPattern
        leftBracket: [
        elements
          VariablePattern
            type: NamedType
              name: SimpleIdentifier
                token: int
                staticElement: dart:core::@class::int
                staticType: null
              type: int
            name: a
            declaredElement: a@51
              type: int
          RelationalPattern
            operator: ==
            operand: SimpleIdentifier
              token: a
              staticElement: a@51
              staticType: int
            element: dart:core::@class::Object::@method::==
        rightBracket: ]
        requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a@51
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@51
          staticType: int
        semicolon: ;
    rightBracket: }
  elseKeyword: else
  elseStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: self::@getter::a
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_single() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a when a > 0) {
    a;
  } else {
    a; // error
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, 75, 1),
    ]);

    final node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  condition: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: a
        declaredElement: a@37
          type: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a@37
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@37
          staticType: int
        semicolon: ;
    rightBracket: }
  elseKeyword: else
  elseStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: <null>
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_rewrite_caseClause_pattern() async {
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
    guardedPattern: GuardedPattern
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

  test_rewrite_expression() async {
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

  test_rewrite_expression_caseClause() async {
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
    guardedPattern: GuardedPattern
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

  test_rewrite_whenClause() async {
    await assertNoErrorsInCode(r'''
void f(x, bool Function() a) {
  if (x case 0 when a()) {}
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
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
      whenClause: WhenClause
        whenKeyword: when
        expression: FunctionExpressionInvocation
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

  test_whenClause() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0 when true) {}
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
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
      whenClause: WhenClause
        whenKeyword: when
        expression: BooleanLiteral
          literal: true
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }
}
