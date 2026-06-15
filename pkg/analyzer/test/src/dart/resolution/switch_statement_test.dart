// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0?:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
    var result = await resolveTestCodeWithDiagnostics('''
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

    var node = result.findNode.simple('value + 1');
    assertResolvedNodeText(node, r'''
SimpleIdentifier
  token: value
  element: value@201
  staticType: int
''');
  }

  test_mergeCases() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.switchStatement('switch');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.switchStatement('switch');
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
                element: <testLibrary>::@class::A
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x, bool Function() a) {
  switch (x) {
    case 0 when a():
      break;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a when a < 0:
    case int a when a > 0:
      a;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@75
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case final int a when a > 0:
      a;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@54
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@87
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a || [int a] when a < 0:
    case int a || [int a] when a > 0:
      a;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
              element: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@48
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
                  element: dart:core::@class::int
                  type: int
                name: a
                declaredFragment: isPublic a@58
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
              element: dart:core::@class::int
              type: int
            name: a
            declaredFragment: isPublic a@86
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
                  element: dart:core::@class::int
                  type: int
                name: a
                declaredFragment: isPublic a@96
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case int a when a > 0:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeDifferentFinalityOrType] The variable 'a' doesn't have the same type and/or finality in all cases that share this body.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@54
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@81
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case final int a when a < 0:
    case num a when a > 0:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeDifferentFinalityOrType] The variable 'a' doesn't have the same type and/or finality in all cases that share this body.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isFinal isPublic a@54
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
            element: dart:core::@class::num
            type: num
          name: a
          declaredFragment: isPublic a@81
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a when a < 0:
    case num a when a > 0:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeDifferentFinalityOrType] The variable 'a' doesn't have the same type and/or finality in all cases that share this body.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
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
            element: dart:core::@class::num
            type: num
          name: a
          declaredFragment: isPublic a@75
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0:
    case int a when a > 0:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeNotAllCases] The variable 'a' is available in some, but not all cases that share this body.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@60
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
    case 0:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeNotAllCases] The variable 'a' is available in some, but not all cases that share this body.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
    default:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeHasLabel] The variable 'a' is not available because there is a label or 'default' case.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case var a:
    case var a:
//  ^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchCase] This case is covered by the previous cases.
    default:
//  ^^^^^^^
// [diag.deadCode] Dead code.
      a;
//    ^
// [diag.patternVariableSharedCaseScopeHasLabel] The variable 'a' is not available because there is a label or 'default' case.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    myLabel:
//  ^^^^^^^^
// [diag.unusedLabel] The label 'myLabel' isn't used.
    case int a when a > 0:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeHasLabel] The variable 'a' is not available because there is a label or 'default' case.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
          name: myLabel
          colon: :
          declaredFragment: <testLibraryFragment> myLabel@39
      keyword: case
      guardedPattern: GuardedPattern
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@61
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a:
    case double b:
    case String c:
      a;
//    ^
// [diag.patternVariableSharedCaseScopeNotAllCases] The variable 'a' is available in some, but not all cases that share this body.
      b;
//    ^
// [diag.patternVariableSharedCaseScopeNotAllCases] The variable 'b' is available in some, but not all cases that share this body.
      c;
//    ^
// [diag.patternVariableSharedCaseScopeNotAllCases] The variable 'c' is available in some, but not all cases that share this body.
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
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
            element: dart:core::@class::double
            type: double
          name: b
          declaredFragment: isPublic b@67
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
            element: dart:core::@class::String
            type: String
          name: c
          declaredFragment: isPublic c@86
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case <int>[var a || var a]:
//                   ^^^^^^^^
// [diag.deadCode] Dead code.
      a;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
                element: dart:core::@class::int
                type: int
            rightBracket: >
          leftBracket: [
          elements
            LogicalOrPattern
              leftOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredFragment: isPublic a@54
                  element: hasImplicitType isPublic
                    type: int
                matchedValueType: int
              operator: ||
              rightOperand: DeclaredVariablePattern
                keyword: var
                name: a
                declaredFragment: isPublic a@63
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = 0;
void f(Object? x) {
  switch (x) {
    case [int a, == a] when a > 0:
//            ^
// [context 1] The declaration of 'a' is here.
//                  ^
// [diag.nonConstantRelationalPatternExpression] The relational pattern expression must be a constant.
// [diag.referencedBeforeDeclaration][context 1] Local variable 'a' can't be referenced before it is declared.
      a;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
                element: dart:core::@class::int
                type: int
              name: a
              declaredFragment: isPublic a@62
                element: isPublic
                  type: int
              matchedValueType: Object?
            RelationalPattern
              operator: ==
              operand: SimpleIdentifier
                token: a
                element: a@62
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case int a when a > 0:
      a;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@48
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0 when true:
      break;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case 0:
      break;
    default:
      break;
  }
}
''');

    var node = result.findNode.switchStatement('switch');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.switchStatement('switch');
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
