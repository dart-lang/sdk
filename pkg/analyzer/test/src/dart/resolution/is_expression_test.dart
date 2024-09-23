// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IsExpressionResolutionTest);
  });
}

@reflectiveTest
class IsExpressionResolutionTest extends PubPackageResolutionTest {
  test_expression_super() async {
    await assertErrorsInCode('''
class A<T> {
  void f() {
    super is T;
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 30, 5),
    ]);

    var node = findNode.singleIsExpression;
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SuperExpression
    superKeyword: super
    staticType: A<T>
  isOperator: is
  type: NamedType
    name: T
    element: T@8
    element2: <not-implemented>
    type: T
  staticType: bool
''');
  }

  test_expression_switchExpression() async {
    await assertNoErrorsInCode('''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  } is double);
}
''');

    var node = findNode.isExpression('is double');
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
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
    element: dart:core::<fragment>::@class::double
    element2: dart:core::<fragment>::@class::double#element
    type: double
  staticType: bool
''');
  }

  test_is() async {
    await assertNoErrorsInCode('''
void f(Object? a) {
  a is int;
}
''');

    var node = findNode.singleIsExpression;
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: Object?
  isOperator: is
  type: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  staticType: bool
''');
  }

  test_isNot() async {
    await assertNoErrorsInCode('''
void f(Object? a) {
  a is! int;
}
''');

    var node = findNode.singleIsExpression;
    assertResolvedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: a
    staticElement: <testLibraryFragment>::@function::f::@parameter::a
    element: <testLibraryFragment>::@function::f::@parameter::a#element
    staticType: Object?
  isOperator: is
  notOperator: !
  type: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  staticType: bool
''');
  }
}
