// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementResolutionTest);
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@37
            type: int
          matchedValueType: Object?
        operator: ||
        rightOperand: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: int
                element: dart:core::<fragment>::@class::int
                element2: dart:core::<fragment>::@class::int#element
                type: int
              name: a
              declaredElement: a@47
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
            staticElement: a[a@37, a@47]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a[a@37, a@47]
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_nested() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case <int>[var a || var a] when a > 0) {
    a;
  }
}
''', [
      error(WarningCode.DEAD_CODE, 45, 8),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
          rightBracket: >
        leftBracket: [
        elements
          LogicalOrPattern
            leftOperand: DeclaredVariablePattern
              keyword: var
              name: a
              declaredElement: hasImplicitType a@43
                type: int
              matchedValueType: int
            operator: ||
            rightOperand: DeclaredVariablePattern
              keyword: var
              name: a
              declaredElement: hasImplicitType a@52
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
            staticElement: a[a@43, a@52]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a[a@43, a@52]
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_notConsistent_differentFinality() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || [final int a] when a > 0) {
    a;
  }
}
''', [
      error(
          CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR, 53, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@37
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
                element: dart:core::<fragment>::@class::int
                element2: dart:core::<fragment>::@class::int#element
                type: int
              name: a
              declaredElement: isFinal a@53
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
            staticElement: notConsistent a[a@37, a@53]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@53]
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr2_notConsistent_differentType() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || [double a] when a > 0) {
    a;
  }
}
''', [
      error(
          CompileTimeErrorCode.INCONSISTENT_PATTERN_VARIABLE_LOGICAL_OR, 50, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@37
            type: int
          matchedValueType: Object?
        operator: ||
        rightOperand: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: double
                element: dart:core::<fragment>::@class::double
                element2: dart:core::<fragment>::@class::double#element
                type: double
              name: a
              declaredElement: a@50
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
            staticElement: notConsistent a[a@37, a@50]
            element: a@-1
            staticType: InvalidType
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: <null>
            staticType: int
          staticElement: <null>
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
          staticElement: notConsistent a[a@37, a@50]
          element: a@-1
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_1() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || 2 || 3 when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 42, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 47, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@37
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
            staticElement: notConsistent a[a@37]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
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
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_12() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || int a || 3 when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 51, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@37
              type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@46
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
            staticElement: notConsistent a[a@37, a@46]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@46]
          element: a@-1
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@37
              type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@46
              type: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@55
            type: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a[a@37, a@46, a@55]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a[a@37, a@46, a@55]
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_13() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case int a || 2 || int a when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 42, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@37
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
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@51
            type: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@37, a@51]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@37, a@51]
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_2() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case 1 || int a || 3 when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 33, 1),
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 47, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@42
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
            staticElement: notConsistent a[a@42]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@42]
          element: a@-1
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_logicalOr3_23() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case 1 || int a || int a when a > 0) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 33, 1),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@42
              type: int
            matchedValueType: Object?
          matchedValueType: Object?
        operator: ||
        rightOperand: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@51
            type: int
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@42, a@51]
            element: a@-1
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
          staticInvokeType: bool Function(num)
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@42, a@51]
          element: a@-1
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
      error(CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION, 57,
          1),
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 57, 1,
          contextMessages: [message(testFile, 51, 1)]),
    ]);

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
              element: dart:core::<fragment>::@class::int
              element2: dart:core::<fragment>::@class::int#element
              type: int
            name: a
            declaredElement: a@51
              type: int
            matchedValueType: Object?
          RelationalPattern
            operator: ==
            operand: SimpleIdentifier
              token: a
              staticElement: a@51
              element: a@51
              staticType: int
            element: dart:core::<fragment>::@class::Object::@method::==
            element2: dart:core::<fragment>::@class::Object::@method::==#element
            matchedValueType: Object?
        rightBracket: ]
        matchedValueType: Object?
        requiredType: List<Object?>
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a@51
            element: a@51
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
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
          staticElement: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_caseClause_variables_scope_logicalOr() async {
    await assertErrorsInCode(r'''
const a = 0;
void f(Object? x) {
  if (x case bool a || a when a) {
    a;
  } else {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_VARIABLE_PATTERN, 56, 1),
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 56, 1),
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
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: LogicalOrPattern
        leftOperand: DeclaredVariablePattern
          type: NamedType
            name: bool
            element: dart:core::<fragment>::@class::bool
            element2: dart:core::<fragment>::@class::bool#element
            type: bool
          name: a
          declaredElement: a@51
            type: bool
          matchedValueType: Object?
        operator: ||
        rightOperand: ConstantPattern
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@51]
            element: a@-1
            staticType: InvalidType
          matchedValueType: Object?
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@51]
          element: a@-1
          staticType: bool
  rightParenthesis: )
  thenStatement: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: notConsistent a[a@51]
          element: a@-1
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
          staticElement: <testLibraryFragment>::@getter::a
          element: <testLibraryFragment>::@getter::a#element
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

    var node = findNode.ifStatement('if');
    assertResolvedNodeText(node, r'''
IfStatement
  ifKeyword: if
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: Object?
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
        name: a
        declaredElement: a@37
          type: int
        matchedValueType: Object?
      whenClause: WhenClause
        whenKeyword: when
        expression: BinaryExpression
          leftOperand: SimpleIdentifier
            token: a
            staticElement: a@37
            element: a@37
            staticType: int
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
            parameter: dart:core::<fragment>::@class::num::@method::>::@parameter::other
            staticType: int
          staticElement: dart:core::<fragment>::@class::num::@method::>
          element: dart:core::<fragment>::@class::num::@method::>#element
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
          staticElement: <null>
          element: <null>
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_expression_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    if (super) {}
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 31, 5),
      error(CompileTimeErrorCode.NON_BOOL_CONDITION, 31, 5),
    ]);

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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: dynamic
  caseClause: CaseClause
    caseKeyword: case
    guardedPattern: GuardedPattern
      pattern: ConstantPattern
        const: const
        expression: InstanceCreationExpression
          constructorName: ConstructorName
            type: NamedType
              name: A
              element: <testLibraryFragment>::@class::A
              element2: <testLibraryFragment>::@class::A#element
              type: A
            staticElement: <testLibraryFragment>::@class::A::@constructor::new
            element: <testLibraryFragment>::@class::A::@constructor::new#element
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: bool Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::a
      element: <testLibraryFragment>::@function::f::@parameter::a#element
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
            staticElement: <testLibraryFragment>::@function::f::@parameter::a
            element: <testLibraryFragment>::@function::f::@parameter::a#element
            staticType: bool Function()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticElement: <null>
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
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
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
