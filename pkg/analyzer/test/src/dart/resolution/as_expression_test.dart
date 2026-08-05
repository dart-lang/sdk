// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AsExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AsExpressionResolutionTest extends PubPackageResolutionTest {
  test_expression_constVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
const num a = 1.2;
const int b = a as int;
//            ^^^^^^^^
// [diag.constEvalThrowsException] Evaluation of this constant expression throws an exception.
''');

    var node = result.findNode.asExpression('as int');
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: num
  asOperator: as
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  staticType: int
''');
  }

  test_expression_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  num v = 42;
  v as int;
}
''');

    var node = result.findNode.singleAsExpression;
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: v
    element: v@17
    staticType: num
  asOperator: as
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  staticType: int
''');
  }

  test_expression_super() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A<T> {
  void f() {
    super as T;
//  ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleAsExpression;
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SuperExpression
    superKeyword: super
    staticType: A<T>
  asOperator: as
  type: NamedType
    name: T
    element: #E0 T
    type: T
  staticType: T
''');
  }

  test_expression_switchExpression() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f(Object? x) {
  (switch (x) {
    _ => 0,
  } as double);
}
''');

    var node = result.findNode.singleAsExpression;
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
    element: dart:core::@class::double
    type: double
  staticType: double
''');
  }
}
