// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_constVariable() async {
    await assertErrorsInCode('''
const num a = 1.2;
const int b = a as int;
''', [
      error(CompileTimeErrorCode.CONST_EVAL_THROWS_EXCEPTION, 33, 8),
    ]);

    var node = findNode.asExpression('as int');
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: a
    staticElement: self::@getter::a
    staticType: num
  asOperator: as
  type: NamedType
    name: SimpleIdentifier
      token: int
      staticElement: dart:core::@class::int
      staticType: null
    type: int
  staticType: int
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

    var node = findNode.asExpression('as double');
    assertResolvedNodeText(node, r'''
AsExpression
  expression: SwitchExpression
    switchKeyword: switch
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
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
    name: SimpleIdentifier
      token: double
      staticElement: dart:core::@class::double
      staticType: null
    type: double
  staticType: double
''');
  }
}
