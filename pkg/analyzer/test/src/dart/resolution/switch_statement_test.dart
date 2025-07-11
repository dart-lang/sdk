// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementResolutionTest);
    defineReflectiveTests(SwitchStatementResolutionTest_Language219);
    defineReflectiveTests(UpdateNodeTextExpectations);
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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

  test_joinedVariables_inLocalFunction() async {
    // Note: this is an important case to test because when variables are inside
    // a local function, their enclosing element is `null`.
    await assertNoErrorsInCode('''
abstract class C {
  List<int> get values;
}
abstract class D {
  List<int> get values;
}
test(Object o) => () {
  switch (o) {
    case C(:var values):
    case D(:var values):
      return [for (var value in values) value + 1];
  }
};
''');

    var node = findNode.simple('value + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: value
  element: value@201
  staticType: int
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      keyword: case
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
              element: <testLibrary>::@function::f::@formalParameter::a
              staticType: bool Function()
            argumentList: ArgumentList
              leftParenthesis: (
              rightParenthesis: )
            element: <null>
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@48
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@75
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@75
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@54
            type: int
            element: isFinal isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@54
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@87
            type: int
            element: isFinal isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@87
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@48
              type: int
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
                declaredFragment: isPublic a@58
                  type: int
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
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
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
              element2: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@86
              type: int
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
                declaredFragment: isPublic a@96
                  type: int
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
      colon: :
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

  test_variables_joinedCase_declareBoth_notConsistent_differentFinality() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case int a when a > 0:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode
              .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
          101,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@54
            type: int
            element: isFinal isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@54
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@81
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@81
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

  test_variables_joinedCase_declareBoth_notConsistent_differentFinalityTypes() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case num a when a > 0:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode
              .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
          101,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@54
            type: int
            element: isFinal isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@54
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: num
            element2: dart:core::@class::num
            type: num
          name: a
          declaredFragment: isPublic a@81
            type: num
            element: isPublic
              type: num
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@81
              staticType: num
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

  test_variables_joinedCase_declareBoth_notConsistent_differentTypes() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case int a when a < 0:
    case num a when a > 0:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode
              .PATTERN_VARIABLE_SHARED_CASE_SCOPE_DIFFERENT_FINALITY_OR_TYPE,
          95,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@48
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: num
            element2: dart:core::@class::num
            type: num
          name: a
          declaredFragment: isPublic a@75
            type: num
            element: isPublic
              type: num
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@75
              staticType: num
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

  test_variables_joinedCase_declareFirst() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case int a when a > 0:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          80,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@60
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@60
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

  test_variables_joinedCase_declareSecond() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
    case 0:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          80,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@48
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
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
            element: a@null
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_hasDefault() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
    default:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
          81,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@48
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
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
            element: a@null
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_hasDefault2() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case var a:
    case var a:
    default:
      a;
  }
}
''',
      [
        error(WarningCode.DEAD_CODE, 55, 4),
        error(WarningCode.UNREACHABLE_SWITCH_CASE, 55, 4),
        error(WarningCode.DEAD_CODE, 71, 7),
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
          86,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
          declaredFragment: isPublic a@48
            type: null
            element: hasImplicitType isPublic
              type: Object?
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: a
          declaredFragment: isPublic a@64
            type: null
            element: hasImplicitType isPublic
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
            element: a@null
            staticType: Object?
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_joinedCase_hasLabel() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    myLabel:
    case int a when a > 0:
      a;
  }
}
''',
      [
        error(WarningCode.UNUSED_LABEL, 39, 8),
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_HAS_LABEL,
          81,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: Object?
  rightParenthesis: )
  leftBracket: {
  members
    SwitchPatternCase
      labels
        Label
          label: SimpleIdentifier
            token: myLabel
            element: myLabel@39
            staticType: null
          colon: :
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@61
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@61
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
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

  test_variables_joinedCase_notConsistent3() async {
    await assertErrorsInCode(
      r'''
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
''',
      [
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          95,
          1,
        ),
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          104,
          1,
        ),
        error(
          CompileTimeErrorCode.PATTERN_VARIABLE_SHARED_CASE_SCOPE_NOT_ALL_CASES,
          113,
          1,
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: double
            element2: dart:core::@class::double
            type: double
          name: b
          declaredFragment: isPublic b@67
            type: double
            element: isPublic
              type: double
          matchedValueType: Object?
      colon: :
    SwitchPatternCase
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: String
            element2: dart:core::@class::String
            type: String
          name: c
          declaredFragment: isPublic c@86
            type: String
            element: isPublic
              type: String
          matchedValueType: Object?
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: a@null
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: b
            element: b@null
            staticType: double
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: c
            element: c@null
            staticType: String
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_logicalOr() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case <int>[var a || var a]:
      a;
  }
}
''',
      [error(WarningCode.DEAD_CODE, 56, 8)],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
                element2: dart:core::@class::int
                type: int
            rightBracket: >
          leftBracket: [
          elements
            LogicalOrPattern
              leftOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredFragment: isPublic a@54
                  type: null
                  element: hasImplicitType isPublic
                    type: int
                matchedValueType: int
              operator: ||
              rightOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredFragment: isPublic a@63
                  type: null
                  element: hasImplicitType isPublic
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
            element: a@null
            staticType: int
          semicolon: ;
  rightBracket: }
''');
  }

  test_variables_scope() async {
    await assertErrorsInCode(
      r'''
const a = 0;
void f(Object? x) {
  switch (x) {
    case [int a, == a] when a > 0:
      a;
  }
}
''',
      [
        error(
          CompileTimeErrorCode.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION,
          68,
          1,
        ),
        error(
          CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
          68,
          1,
          contextMessages: [message(testFile, 62, 1)],
        ),
      ],
    );

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
                element2: dart:core::@class::int
                type: int
              name: a
              declaredFragment: isPublic a@62
                type: int
                element: isPublic
                  type: int
              matchedValueType: Object?
            RelationalPattern
              operator: ==
              operand: SimpleIdentifier
                token: a
                element: a@62
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
              element: a@62
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: a@62
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
            type: int
            element: isPublic
              type: int
          matchedValueType: Object?
        whenClause: WhenClause
          whenKeyword: when
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              element: a@48
              staticType: int
            operator: >
            rightOperand: IntegerLiteral
              literal: 0
              correspondingParameter: dart:core::@class::num::@method::>::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::>
            staticInvokeType: bool Function(num)
            staticType: bool
      colon: :
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: a
            element: a@48
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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

    var node = findNode.switchStatement('switch');
    assertResolvedNodeText(node, r'''
SwitchStatement
  switchKeyword: switch
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
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
