// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IsExpressionResolutionTest extends PubPackageResolutionTest {
  test_expression_super() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  void f() {
    super is T;
//  ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleIsExpression;
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SuperExpression
    superKeyword: super
    staticType: A<T>
  isOperator: is
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: bool
''');
  }

  test_expression_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  } is double);
}
''');

    var node = result.findNode.isExpression('is double');
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object?
    rightParenthesis: )
    leftBracket: {
    cases
      SwitchExpressionCase
        guardedPattern: GuardedPattern
          pattern: WildcardPattern
            name: _
            matchedValueType: Object?
        arrow: =>
        expression: IntegerLiteral
          literal: 0
          staticType: int
    rightBracket: }
    staticType: int
  isOperator: is
  type: NamedType
    name: double
    element: dart:core::@class::double
    type: double
  staticType: bool
''');
  }

  test_is() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object? a) {
  a is int;
}
''');

    var node = result.findNode.singleIsExpression;
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Object?
  isOperator: is
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  staticType: bool
''');
  }

  test_isNot() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object? a) {
  a is! int;
}
''');

    var node = result.findNode.singleIsExpression;
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@function::f::@formalParameter::a
    staticType: Object?
  isOperator: is
  notOperator: !
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  staticType: bool
''');
  }
}
