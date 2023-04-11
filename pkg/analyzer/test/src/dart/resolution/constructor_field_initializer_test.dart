// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstructorFieldInitializerResolutionTest);
  });
}

@reflectiveTest
class ConstructorFieldInitializerResolutionTest
    extends PubPackageResolutionTest {
  test_formalParameter() async {
    await assertNoErrorsInCode('''
class A {
  final int f;
  A(int a) : f = a;
}
''');

    final node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: f
    staticElement: self::@class::A::@field::f
    staticType: null
  equals: =
  expression: SimpleIdentifier
    token: a
    staticElement: self::@class::A::@constructor::new::@parameter::a
    staticType: int
''');
  }

  test_functionExpressionInvocation_blockBody() async {
    await resolveTestCode(r'''
class A {
  final x;
  A(int a) : x = (() {return a + 1;})();
}
''');

    final node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: self::@class::A::@field::x
    staticType: null
  equals: =
  expression: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ReturnStatement
                returnKeyword: return
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: a
                    staticElement: self::@class::A::@constructor::new::@parameter::a
                    staticType: int
                  operator: +
                  rightOperand: IntegerLiteral
                    literal: 1
                    parameter: dart:core::@class::num::@method::+::@parameter::other
                    staticType: int
                  staticElement: dart:core::@class::num::@method::+
                  staticInvokeType: num Function(num)
                  staticType: int
                semicolon: ;
            rightBracket: }
        declaredElement: @39
          type: int Function()
        staticType: int Function()
      rightParenthesis: )
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function()
    staticType: int
''');
  }

  test_functionExpressionInvocation_expressionBody() async {
    await resolveTestCode(r'''
class A {
  final int x;
  A(int a) : x = (() => a + 1)();
}
''');

    final node = findNode.singleConstructorFieldInitializer;
    assertResolvedNodeText(node, r'''
ConstructorFieldInitializer
  fieldName: SimpleIdentifier
    token: x
    staticElement: self::@class::A::@field::x
    staticType: null
  equals: =
  expression: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: BinaryExpression
            leftOperand: SimpleIdentifier
              token: a
              staticElement: self::@class::A::@constructor::new::@parameter::a
              staticType: int
            operator: +
            rightOperand: IntegerLiteral
              literal: 1
              parameter: dart:core::@class::num::@method::+::@parameter::other
              staticType: int
            staticElement: dart:core::@class::num::@method::+
            staticInvokeType: num Function(num)
            staticType: int
        declaredElement: @43
          type: int Function()
        staticType: int Function()
      rightParenthesis: )
      staticType: int Function()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticElement: <null>
    staticInvokeType: int Function()
    staticType: int
''');
  }
}
