// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementResolutionTest);
    defineReflectiveTests(InferenceUpdate4Test);
  });
}

@reflectiveTest
class IfStatementResolutionTest extends PubPackageResolutionTest {
  test_caseClause() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case 0) {}
}
''');

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_consistent() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || [int a] when a > 0) {
    a;
  }
}
''');

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@37
            element: isPublic
              type: int
          matchedValueType: Object?
        operator: ||
        rightOperand: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: int
                element2: dart:core::@class::int
                type: int
              name: a
              declaredFragment: isPublic a@47
                element: isPublic
                  type: int
              matchedValueType: Object?
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<Object?>
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_nested() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case <int>[var a || var a] when a > 0) {
    a;
  }
}
''',
      [error(WarningCode.deadCode, 45, 8)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ListPattern
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element2: dart:core::@class::int
              type: int
          rightBracket: >
        leftBracket: [
        elements
          LogicalOrPattern
            leftOperand: DeclaredVariablePattern
              keyword: var
              name: a
              declaredFragment: isPublic a@43
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            operator: ||
            rightOperand: DeclaredVariablePattern
              keyword: var
              name: a
              declaredFragment: isPublic a@52
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            matchedValueType: int
        rightBracket: ]
        matchedValueType: Object?
        requiredType: List<int>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_notConsistent_differentFinality() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case int a || [final int a] when a > 0) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.inconsistentPatternVariableLogicalOr, 53, 1)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@37
            element: isPublic
              type: int
          matchedValueType: Object?
        operator: ||
        rightOperand: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              keyword: final
              type: NamedType
                name: int
                element2: dart:core::@class::int
                type: int
              name: a
              declaredFragment: isFinal isPublic a@53
                element: isFinal isPublic
                  type: int
              matchedValueType: Object?
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<Object?>
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_notConsistent_differentType() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case int a || [double a] when a > 0) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.inconsistentPatternVariableLogicalOr, 50, 1)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@37
            element: isPublic
              type: int
          matchedValueType: Object?
        operator: ||
        rightOperand: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: double
                element2: dart:core::@class::double
                type: double
              name: a
              declaredFragment: isPublic a@50
                element: isPublic
                  type: double
              matchedValueType: Object?
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<Object?>
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: InvalidType
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: <null>
            staticType: int
          element: <null>
          staticInvokeType: null
          staticType: InvalidType
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_1() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case int a || 2 || 3 when a > 0) {
    a;
  }
}
''',
      [
        error(CompileTimeErrorCode.missingVariablePattern, 42, 1),
        error(CompileTimeErrorCode.missingVariablePattern, 47, 1),
      ],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@37
              element: isPublic
                type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 2
              staticType: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: ConstantPattern
          expression: IntegerLiteral
            literal: 3
            staticType: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_12() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case int a || int a || 3 when a > 0) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.missingVariablePattern, 51, 1)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@37
              element: isPublic
                type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@46
              element: isPublic
                type: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: ConstantPattern
          expression: IntegerLiteral
            literal: 3
            staticType: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_123() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || int a || int a when a > 0) {
    a;
  }
}
''');

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@37
              element: isPublic
                type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@46
              element: isPublic
                type: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@55
            element: isPublic
              type: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_13() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case int a || 2 || int a when a > 0) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.missingVariablePattern, 42, 1)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@37
              element: isPublic
                type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 2
              staticType: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@51
            element: isPublic
              type: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_2() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case 1 || int a || 3 when a > 0) {
    a;
  }
}
''',
      [
        error(CompileTimeErrorCode.missingVariablePattern, 33, 1),
        error(CompileTimeErrorCode.missingVariablePattern, 47, 1),
      ],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 1
              staticType: int
            matchedValueType: Object?
          operator: ||
          rightOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@42
              element: isPublic
                type: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: ConstantPattern
          expression: IntegerLiteral
            literal: 3
            staticType: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_23() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case 1 || int a || int a when a > 0) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.missingVariablePattern, 33, 1)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: ConstantPattern
            expression: IntegerLiteral
              literal: 1
              staticType: int
            matchedValueType: Object?
          operator: ||
          rightOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@42
              element: isPublic
                type: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@51
            element: isPublic
              type: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
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
    await assertErrorsInCode(
      r'''
const a = 0;
void f(Object? x) {
  if (x case [int a, == a] when a > 0) {
    a;
  } else {
    a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.nonConstantRelationalPatternExpression,
          57,
          1,
        ),
        error(
          CompileTimeErrorCode.referencedBeforeDeclaration,
          57,
          1,
          contextMessages: [message(testFile, 51, 1)],
        ),
      ],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ListPattern
        leftBracket: [
        elements
          DeclaredVariablePattern
            type: NamedType
              name: int
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@51
              element: isPublic
                type: int
            matchedValueType: Object?
          RelationalPattern
            operator: ==
            operand: SimpleIdentifier
              token: a
              element: a@51
              staticType: int
            element2: dart:core::@class::Object::@method::==
            matchedValueType: Object?
        rightBracket: ]
        matchedValueType: Object?
        requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@51
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@51
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
          element: <testLibrary>::@getter::a
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_scope_logicalOr() async {
    await assertErrorsInCode(
      r'''
const a = 0;
void f(Object? x) {
  if (x case bool a || a when a) {
    a;
  } else {
    a;
  }
}
''',
      [
        error(CompileTimeErrorCode.missingVariablePattern, 56, 1),
        error(CompileTimeErrorCode.referencedBeforeDeclaration, 56, 1),
      ],
    );

    var node = findNode.singleIfStatement;
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: bool
            element2: dart:core::@class::bool
            type: bool
          name: a
          declaredFragment: isPublic a@51
            element: isPublic
              type: bool
          matchedValueType: Object?
        operator: ||
        rightOperand: ConstantPattern
          expression: SimpleIdentifier
            token: a
            element: a@null
            staticType: InvalidType
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@null
          staticType: bool
        semicolon: ;
    rightBracket: }
  elseKeyword: else
  elseStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@getter::a
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_single() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  if (x case int a when a > 0) {
    a;
  } else {
    a; // error
  }
}
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 75, 1)],
    );

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@37
          element: isPublic
            type: int
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            element: a@37
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
            staticType: int
          element: dart:core::@class::num::@method::>
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@37
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
          element: <null>
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_expression_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    if (super) {}
  }
}
''',
      [
        error(ParserErrorCode.missingAssignableSelector, 31, 5),
        error(CompileTimeErrorCode.nonBoolCondition, 31, 5),
      ],
    );

    var node = findNode.singleIfStatement;
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SuperExpression
    superKeyword: super
    staticType: A
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_rewrite_caseClause_pattern() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  if (x case const A()) {}
}

class A {
  const A();
}
''');

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        constKeyword: const
        expression: InstanceCreationExpression
          constructorName: ConstructorName
            type: NamedType
              name: A
              element2: <testLibrary>::@class::A
              type: A
            element: <testLibrary>::@class::A::@constructor::new
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticType: A
        matchedValueType: dynamic
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

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: bool Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
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

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: FunctionExpressionInvocation
    function: SimpleIdentifier
      token: a
      element: <testLibrary>::@function::f::@formalParameter::a
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    element: <null>
    staticInvokeType: int Function()
    staticType: int
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 42
          staticType: int
        matchedValueType: int
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

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
      whenClause: WhenClause
        whenKeyword: when
        expression: FunctionExpressionInvocation
          function: SimpleIdentifier
            token: a
            element: <testLibrary>::@function::f::@formalParameter::a
            staticType: bool Function()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          element: <null>
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

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
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

@reflectiveTest
class InferenceUpdate4Test extends PubPackageResolutionTest {
  @override
  List<String> get experiments {
    return [...super.experiments, Feature.inference_update_4.enableString];
  }

  test_finalPromotionKept_isExpression() async {
    await assertNoErrorsInCode('''
f(bool b) {
  final num x;
  if (b) {
    x = 1;
  } else {
    x = 0.1;
  }
  if (x is int) {
    () => x.isEven;
  }
}
''');

    assertResolvedNodeText(findNode.ifStatement('if (x is int) {'), r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: IsExpression
    expression: SimpleIdentifier
      token: x
      element: x@24
      staticType: num
    isOperator: is
    type: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: x
                element: x@24
                staticType: int
              period: .
              identifier: SimpleIdentifier
                token: isEven
                element: dart:core::@class::int::@getter::isEven
                staticType: bool
              element: dart:core::@class::int::@getter::isEven
              staticType: bool
          declaredElement: <testLibraryFragment> null@null
            element: null@null
              type: bool Function()
          staticType: bool Function()
        semicolon: ;
    rightBracket: }
''');
  }

  test_finalPromotionKept_isExpression_late() async {
    await assertNoErrorsInCode('''
f(bool b) {
  late final num x;
  if (b) {
    x = 1;
  } else {
    x = 0.1;
  }
  if (x is int) {
    () => x.isEven;
  }
}
''');

    assertResolvedNodeText(findNode.ifStatement('if (x is int) {'), r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: IsExpression
    expression: SimpleIdentifier
      token: x
      element: x@29
      staticType: num
    isOperator: is
    type: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: x
                element: x@29
                staticType: int
              period: .
              identifier: SimpleIdentifier
                token: isEven
                element: dart:core::@class::int::@getter::isEven
                staticType: bool
              element: dart:core::@class::int::@getter::isEven
              staticType: bool
          declaredElement: <testLibraryFragment> null@null
            element: null@null
              type: bool Function()
          staticType: bool Function()
        semicolon: ;
    rightBracket: }
''');
  }

  test_finalPromotionKept_notEqNull() async {
    await assertNoErrorsInCode('''
f(bool b) {
  final int? x;
  if (b) {
    x = 1;
  } else {
    x = null;
  }
  if (x != null) {
    () => x.isEven;
  }
}
''');

    assertResolvedNodeText(findNode.ifStatement('if (x != null) {'), r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
      element: x@25
      staticType: int?
    operator: !=
    rightOperand: NullLiteral
      literal: null
      correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
      staticType: Null
    element: dart:core::@class::num::@method::==
    staticInvokeType: bool Function(Object)
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: x
                element: x@25
                staticType: int
              period: .
              identifier: SimpleIdentifier
                token: isEven
                element: dart:core::@class::int::@getter::isEven
                staticType: bool
              element: dart:core::@class::int::@getter::isEven
              staticType: bool
          declaredElement: <testLibraryFragment> null@null
            element: null@null
              type: bool Function()
          staticType: bool Function()
        semicolon: ;
    rightBracket: }
''');
  }

  test_finalPromotionKept_notEqNull_late() async {
    await assertNoErrorsInCode('''
f(bool b) {
  late final int? x;
  if (b) {
    x = 1;
  } else {
    x = null;
  }
  if (x != null) {
    () => x.isEven;
  }
}
''');

    assertResolvedNodeText(findNode.ifStatement('if (x != null) {'), r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
      element: x@30
      staticType: int?
    operator: !=
    rightOperand: NullLiteral
      literal: null
      correspondingParameter: dart:core::@class::num::@method::==::@formalParameter::other
      staticType: Null
    element: dart:core::@class::num::@method::==
    staticInvokeType: bool Function(Object)
    staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: FunctionExpression
          parameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
          body: ExpressionFunctionBody
            functionDefinition: =>
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: x
                element: x@30
                staticType: int
              period: .
              identifier: SimpleIdentifier
                token: isEven
                element: dart:core::@class::int::@getter::isEven
                staticType: bool
              element: dart:core::@class::int::@getter::isEven
              staticType: bool
          declaredElement: <testLibraryFragment> null@null
            element: null@null
              type: bool Function()
          staticType: bool Function()
        semicolon: ;
    rightBracket: }
''');
  }
}
