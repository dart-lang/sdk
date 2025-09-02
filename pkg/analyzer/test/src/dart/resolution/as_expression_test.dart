// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsExpressionResolutionTest);
  });
}

@reflectiveTest
class AsExpressionResolutionTest extends PubPackageResolutionTest {
  test_expression_constVariable() async {
    await assertErrorsInCode(
      '''
const num a = 1.2;
const int b = a as int;
''',
      [error(CompileTimeErrorCode.constEvalThrowsException, 33, 8)],
    );

    var node = findNode.asExpression('as int');
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: num
  asOperator: as
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  staticType: int
''');
  }

  test_expression_localVariable() async {
    await assertNoErrorsInCode('''
void f() {
  num v = 42;
  v as int;
}
''');

    var node = findNode.singleAsExpression;
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: v
    element: v@17
    staticType: num
  asOperator: as
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  staticType: int
''');
  }

  test_expression_super() async {
    await assertErrorsInCode(
      '''
class A<T> {
  void f() {
    super as T;
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 30, 5)],
    );

    var node = findNode.singleAsExpression;
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SuperExpression
    superKeyword: super
    staticType: A<T>
  asOperator: as
  type: NamedType
    name: T
    element2: #E0 T
    type: T
  staticType: T
''');
  }

  test_expression_switchExpression() async {
    await assertNoErrorsInCode('''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  } as double);
}
''');

    var node = findNode.singleAsExpression;
    assertResolvedNodeText(node, r'''
AsExpression
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
  asOperator: as
  type: NamedType
    name: double
    element2: dart:core::@class::double
    type: double
  staticType: double
''');
  }
}
