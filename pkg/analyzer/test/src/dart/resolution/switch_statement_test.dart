// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementResolutionTest);
    defineReflectiveTests(SwitchStatementResolutionTest_Language219);
  });
}

@reflectiveTest
class SwitchStatementResolutionTest extends PubPackageResolutionTest {
  test_default() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0?:
      break;
    default:
      break;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: NullCheckPattern
          pattern: ConstantPattern
            expression: IntegerLiteral
              literal: 0
              staticType: int
            matchedValueType: Object
          operator: ?
          matchedValueType: Object?
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchDefault
      keyword: default
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  test_mergeCases() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0?:
    case 1?:
      break;
    case 2?:
      break;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: NullCheckPattern
          pattern: ConstantPattern
            expression: IntegerLiteral
              literal: 0
              staticType: int
            matchedValueType: Object
          operator: ?
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: NullCheckPattern
          pattern: ConstantPattern
            expression: IntegerLiteral
              literal: 1
              staticType: int
            matchedValueType: Object
          operator: ?
          matchedValueType: Object?
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: NullCheckPattern
          pattern: ConstantPattern
            expression: IntegerLiteral
              literal: 2
              staticType: int
            matchedValueType: Object
          operator: ?
          matchedValueType: Object?
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  /// https://github.com/dart-lang/sdk/issues/52425
  test_partLanguage219_switchCase() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
// @dart = 2.9
part of 'test.dart';

void f(Object? x) {
  switch (x) {
    case 0:
      break;
  }
}
''');

    await assertErrorsInCode(r'''
part 'a.dart';
''', [
      error(CompileTimeErrorCode.INCONSISTENT_LANGUAGE_VERSION_OVERRIDE, 5, 8),
    ]);

    await resolveFile2(a.path);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchCase
      keyword: case
      expression: IntegerLiteral
        literal: 0
        staticType: int
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  test_rewrite_pattern() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case const A():
      break;
  }
}

class A {
  const A();
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          const: const
          expression: InstanceCreationExpression
            constructorName: ConstructorName
              type: NamedType
                name: A
                element: self::@class::A
                type: A
              staticElement: self::@class::A::@constructor::new
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            staticType: A
          matchedValueType: Object?
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  test_rewrite_whenClause() async {
    await assertNoErrorsInCode(r'''
void f(Object? x, bool Function() a) {
  switch (x) {
    case 0 when a():
      break;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
            staticType: int
          matchedValueType: Object?
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
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareBoth_consistent() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a when a < 0:
    case int a when a > 0:
      a;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@48
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@48
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::<::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@75
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@75
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: a[a@48, a@75]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareBoth_consistent_final() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case final int a when a > 0:
      a;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: isFinal a@54
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@54
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::<::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: isFinal a@87
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@87
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: final a[a@54, a@87]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareBoth_consistent_logicalOr2() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a || [int a] when a < 0:
    case int a || [int a] when a > 0:
      a;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::@class::int
              type: int
            name: a
            declaredElement: a@48
              type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: ListPattern
            leftBracket: [
            elements
              DeclaredVariablePattern
                type: NamedType
                  name: int
                  element: dart:core::@class::int
                  type: int
                name: a
                declaredElement: a@58
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
              staticElement: a[a@48, a@58]
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::<::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: LogicalOrPattern
          leftOperand: DeclaredVariablePattern
            type: NamedType
              name: int
              element: dart:core::@class::int
              type: int
            name: a
            declaredElement: a@86
              type: int
            matchedValueType: Object?
          operator: ||
          rightOperand: ListPattern
            leftBracket: [
            elements
              DeclaredVariablePattern
                type: NamedType
                  name: int
                  element: dart:core::@class::int
                  type: int
                name: a
                declaredElement: a@96
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
              staticElement: a[a@86, a@96]
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: a[a[a@48, a@58], a[a@86, a@96]]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareBoth_notConsistent_differentFinality() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case int a when a > 0:
      a;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
          101,
          1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: isFinal a@54
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@54
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::<::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@81
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@81
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@54, a@81]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareBoth_notConsistent_differentFinalityTypes() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case num a when a > 0:
      a;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
          101,
          1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: final
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: isFinal a@54
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@54
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::<::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: num
            element: dart:core::@class::num
            type: num
          name: a
          declaredElement: a@81
            type: num
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@81
              staticType: num
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@54, a@81]
            staticType: InvalidType
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareBoth_notConsistent_differentTypes() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a when a < 0:
    case num a when a > 0:
      a;
  }
}
''', [
      error(
          CompileTimeErrorCode
              .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
          95,
          1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@48
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@48
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::<::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: num
            element: dart:core::@class::num
            type: num
          name: a
          declaredElement: a@75
            type: num
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@75
              staticType: num
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@48, a@75]
            staticType: InvalidType
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareFirst() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case int a when a > 0:
      a;
  }
}
''', [
      error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          80,
          1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
            staticType: int
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@60
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@60
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@60]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_declareSecond() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
    case 0:
      a;
  }
}
''', [
      error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          80,
          1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@48
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@48
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
            staticType: int
          matchedValueType: Object?
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@48]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_hasDefault() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
    default:
      a;
  }
}
''', [
      error(CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
          81, 1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@48
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@48
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchDefault
      keyword: default
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@48]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_hasDefault2() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case var a:
    case var a:
    default:
      a;
  }
}
''', [
      error(WarningCode.DEAD_CODE, 55, 4),
      error(WarningCode.UNREACHABLE_SWITCH_CASE, 55, 4),
      error(WarningCode.DEAD_CODE, 71, 7),
      error(CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
          86, 1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: a
          declaredElement: hasImplicitType a@48
            type: Object?
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: a
          declaredElement: hasImplicitType a@64
            type: Object?
          matchedValueType: Object?
      colon: :
    SwitchDefault
      keyword: default
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@48, a@64]
            staticType: Object?
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_hasLabel() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    myLabel:
    case int a when a > 0:
      a;
  }
}
''', [
      error(WarningCode.UNUSED_LABEL, 39, 8),
      error(CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
          81, 1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      labels
        Label
          label: SimpleIdentifier
            token: myLabel
            staticElement: myLabel@39
            staticType: null
          colon: :
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@61
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@61
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@61]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_notConsistent3() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a:
    case double b:
    case String c:
      a;
      b;
      c;
  }
}
''', [
      error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          95,
          1),
      error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          104,
          1),
      error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          113,
          1),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@48
            type: int
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: double
            element: dart:core::@class::double
            type: double
          name: b
          declaredElement: b@67
            type: double
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: String
            element: dart:core::@class::String
            type: String
          name: c
          declaredElement: c@86
            type: String
          matchedValueType: Object?
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: notConsistent a[a@48]
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: b
            staticElement: notConsistent b[b@67]
            staticType: double
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: c
            staticElement: notConsistent c[c@86]
            staticType: String
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_logicalOr() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case <int>[var a || var a]:
      a;
  }
}
''', [
      error(WarningCode.DEAD_CODE, 56, 8),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ListPattern
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: int
                element: dart:core::@class::int
                type: int
            rightBracket: >
          leftBracket: [
          elements
            LogicalOrPattern
              leftOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredElement: hasImplicitType a@54
                  type: int
                matchedValueType: int
              operator: ||
              rightOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredElement: hasImplicitType a@63
                  type: int
                matchedValueType: int
              matchedValueType: int
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<int>
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: a[a@54, a@63]
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_scope() async {
    await assertErrorsInCode(r'''
const a = 0;
void f(Object? x) {
  switch (x) {
    case [int a, == a] when a > 0:
      a;
  }
}
''', [
      error(CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION, 68,
          1),
      error(CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION, 68, 1,
          contextMessages: [message('/home/test/lib/test.dart', 62, 1)]),
    ]);

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ListPattern
          leftBracket: [
          elements
            DeclaredVariablePattern
              type: NamedType
                name: int
                element: dart:core::@class::int
                type: int
              name: a
              declaredElement: a@62
                type: int
              matchedValueType: Object?
            RelationalPattern
              operator: ==
              operand: SimpleIdentifier
                token: a
                staticElement: a@62
                staticType: int
              element: dart:core::@class::Object::@method::==
              matchedValueType: Object?
          rightBracket: ]
          matchedValueType: Object?
          requiredType: List<Object?>
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@62
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: a@62
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_singleCase() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
      a;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: a@48
            type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: a@48
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              parameter: dart:core::@class::num::@method::>::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            staticElement: a@48
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_whenClause() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0 when true:
      break;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: ConstantPattern
          expression: IntegerLiteral
            literal: 0
            staticType: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BooleanLiteral
            literal: true
            staticType: bool
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }
}

@reflectiveTest
class SwitchStatementResolutionTest_Language219 extends PubPackageResolutionTest
    with WithLanguage219Mixin {
  test_default() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
      break;
    default:
      break;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchCase
      keyword: case
      expression: IntegerLiteral
        literal: 0
        staticType: int
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchDefault
      keyword: default
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }

  test_mergeCases() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case 1:
      break;
    case 2:
      break;
  }
}
''');

    final node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchCase
      keyword: case
      expression: IntegerLiteral
        literal: 0
        staticType: int
      colon: :
    SwitchCase
      keyword: case
      expression: IntegerLiteral
        literal: 1
        staticType: int
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
    SwitchCase
      keyword: case
      expression: IntegerLiteral
        literal: 2
        staticType: int
      colon: :
      statements
        BreakStatement
          breakKeyword: break
          semicolon: ;
  rightBracket: }
''');
  }
}
