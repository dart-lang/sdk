// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'simple_parser_test.dart';
library;

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComplexParserTest);
  });
}

/// The class `ComplexParserTest` defines parser tests that test the parsing of
/// more complex code fragments or the interactions between multiple parsing
/// methods. For example, tests to ensure that the precedence of operations is
/// being handled correctly should be defined in this class.
///
/// Simpler tests should be defined in the class [SimpleParserTest].
@reflectiveTest
class ComplexParserTest extends ParserDiagnosticsTest {
  void test_additiveExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x + y - z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: +
    rightOperand: SimpleIdentifier
      token: y
  operator: -
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_additiveExpression_noSpaces() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  i+1;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: i
  operator: +
  rightOperand: IntegerLiteral
    literal: 1
''');
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x * y + z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: *
    rightOperand: SimpleIdentifier
      token: y
  operator: +
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super * y - z;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: *
    rightOperand: SimpleIdentifier
      token: y
  operator: -
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x + y * z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: +
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: *
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_additiveExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super + y - z;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: +
    rightOperand: SimpleIdentifier
      token: y
  operator: -
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_assignableExpression_arguments_normal_chain() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a(b)(c).d(e).f;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: MethodInvocation
    target: FunctionExpressionInvocation
      function: MethodInvocation
        methodName: SimpleIdentifier
          token: a
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: b
          rightParenthesis: )
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: c
        rightParenthesis: )
    operator: .
    methodName: SimpleIdentifier
      token: d
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: e
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: f
''');
  }

  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a<E>(b)<F>(c).d<G>(e).f;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: MethodInvocation
    target: FunctionExpressionInvocation
      function: MethodInvocation
        methodName: SimpleIdentifier
          token: a
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: E
          rightBracket: >
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: b
          rightParenthesis: )
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: F
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: c
        rightParenthesis: )
    operator: .
    methodName: SimpleIdentifier
      token: d
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: G
      rightBracket: >
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: e
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: f
''');
  }

  void test_assignmentExpression_compound() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x = y = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
  operator: =
  rightHandSide: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: y
    operator: =
    rightHandSide: IntegerLiteral
      literal: 0
''');
  }

  void test_assignmentExpression_indexExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x[1] = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: IndexExpression
    target: SimpleIdentifier
      token: x
    leftBracket: [
    index: IntegerLiteral
      literal: 1
    rightBracket: ]
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
''');
  }

  void test_assignmentExpression_prefixedIdentifier() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x.y = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
    period: .
    identifier: SimpleIdentifier
      token: y
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
''');
  }

  void test_assignmentExpression_propertyAccess() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super.y = 0;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: PropertyAccess
    target: SuperExpression
      superKeyword: super
    operator: .
    propertyName: SimpleIdentifier
      token: y
  operator: =
  rightHandSide: IntegerLiteral
    literal: 0
''');
  }

  void test_binary_operator_written_out_expression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x xor y;
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 3)]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    VariableDeclarationStatement
      variables: VariableDeclarationList
        type: NamedType
          name: x
        variables
          VariableDeclaration
            name: xor
      semicolon: ; <synthetic>
    ExpressionStatement
      expression: SimpleIdentifier
        token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_binary_operator_written_out_expression_logical() {
    // Report `and` and recover with a synthetic `&&` in the parsed AST.
    var parseResult = parseStringWithErrors(r'''
void f() {
  x > 0 and y > 1;
}
''');
    parseResult.assertErrors([error(diag.binaryOperatorWrittenOut, 19, 3)]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BinaryExpression
        leftOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: x
          operator: >
          rightOperand: IntegerLiteral
            literal: 0
        operator: && <synthetic>
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: y
          operator: >
          rightOperand: IntegerLiteral
            literal: 1
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bitwiseAndExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x & y & z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: &
    rightOperand: SimpleIdentifier
      token: y
  operator: &
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x == y && z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ==
    rightOperand: SimpleIdentifier
      token: y
  operator: &&
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x && y == z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: &&
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: ==
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_bitwiseAndExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super & y & z;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: &
    rightOperand: SimpleIdentifier
      token: y
  operator: &
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseOrExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x | y | z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: |
    rightOperand: SimpleIdentifier
      token: y
  operator: |
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x ^ y | z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ^
    rightOperand: SimpleIdentifier
      token: y
  operator: |
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x | y ^ z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: |
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: ^
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_bitwiseOrExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super | y | z;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: |
    rightOperand: SimpleIdentifier
      token: y
  operator: |
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseXorExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x ^ y ^ z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ^
    rightOperand: SimpleIdentifier
      token: y
  operator: ^
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x & y ^ z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: &
    rightOperand: SimpleIdentifier
      token: y
  operator: ^
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x ^ y & z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ^
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: &
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_bitwiseXorExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super ^ y ^ z;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: ^
    rightOperand: SimpleIdentifier
      token: y
  operator: ^
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_cascade_withAssignment() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  new Map()..[3] = 4 ..[0] = 11;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: Map
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
  cascadeSections
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 3
        rightBracket: ]
      operator: =
      rightHandSide: IntegerLiteral
        literal: 4
    AssignmentExpression
      leftHandSide: IndexExpression
        period: ..
        leftBracket: [
        index: IntegerLiteral
          literal: 0
        rightBracket: ]
      operator: =
      rightHandSide: IntegerLiteral
        literal: 11
''');
  }

  void test_conditionalExpression_precedence_ifNullExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a ?? b ? y : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: BinaryExpression
    leftOperand: SimpleIdentifier
      token: a
    operator: ??
    rightOperand: SimpleIdentifier
      token: b
  question: ?
  thenExpression: SimpleIdentifier
    token: y
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a | b ? y : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: BinaryExpression
    leftOperand: SimpleIdentifier
      token: a
    operator: |
    rightOperand: SimpleIdentifier
      token: b
  question: ?
  thenExpression: SimpleIdentifier
    token: y
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_as() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x as bool ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: AsExpression
    expression: SimpleIdentifier
      token: x
    asOperator: as
    type: NamedType
      name: bool
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_as2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x as bool? ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: AsExpression
    expression: SimpleIdentifier
      token: x
    asOperator: as
    type: NamedType
      name: bool
      question: ?
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_as3() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  (x as bool?) ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: ParenthesizedExpression
    leftParenthesis: (
    expression: AsExpression
      expression: SimpleIdentifier
        token: x
      asOperator: as
      type: NamedType
        name: bool
        question: ?
    rightParenthesis: )
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_is() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is String ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: String
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_is2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is String? ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: String
      question: ?
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_is3() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  (x is String?) ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: ParenthesizedExpression
    leftParenthesis: (
    expression: IsExpression
      expression: SimpleIdentifier
        token: x
      isOperator: is
      type: NamedType
        name: String
        question: ?
    rightParenthesis: )
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1_is() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is String<S> ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: String
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: S
        rightBracket: >
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1GFT_is() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is String<S> Function() ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: GenericFunctionType
      returnType: NamedType
        name: String
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: S
          rightBracket: >
      functionKeyword: Function
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg2_is() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is String<S,T> ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: String
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: S
          NamedType
            name: T
        rightBracket: >
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_prefixedNullableType_is() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is p.A ? (x + y) : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
      name: A
  question: ?
  thenExpression: ParenthesizedExpression
    leftParenthesis: (
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: x
      operator: +
      rightOperand: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_withAssignment() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  b ? c = true : g();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: b
  question: ?
  thenExpression: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: c
    operator: =
    rightHandSide: BooleanLiteral
      literal: true
  colon: :
  elseExpression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_conditionalExpression_precedence_withAssignment2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  b.x ? c = true : g();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: b
    period: .
    identifier: SimpleIdentifier
      token: x
  question: ?
  thenExpression: AssignmentExpression
    leftHandSide: SimpleIdentifier
      token: c
    operator: =
    rightHandSide: BooleanLiteral
      literal: true
  colon: :
  elseExpression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_conditionalExpression_prefixedValue() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a.b ? y : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
    period: .
    identifier: SimpleIdentifier
      token: b
  question: ?
  thenExpression: SimpleIdentifier
    token: y
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_prefixedValue2() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a.b ? x.y : z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
    period: .
    identifier: SimpleIdentifier
      token: b
  question: ?
  thenExpression: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
    period: .
    identifier: SimpleIdentifier
      token: y
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : this.a = (b == null ? c : d);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorFieldInitializer;
    assertParsedNodeText(node, r'''
ConstructorFieldInitializer
  thisKeyword: this
  period: .
  fieldName: SimpleIdentifier
    token: a
  equals: =
  expression: ParenthesizedExpression
    leftParenthesis: (
    expression: ConditionalExpression
      condition: BinaryExpression
        leftOperand: SimpleIdentifier
          token: b
        operator: ==
        rightOperand: NullLiteral
          literal: null
      question: ?
      thenExpression: SimpleIdentifier
        token: c
      colon: :
      elseExpression: SimpleIdentifier
        token: d
    rightParenthesis: )
''');
  }

  void test_equalityExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x == y != z;
}
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 20, 2),
    ]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BinaryExpression
        leftOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: x
          operator: ==
          rightOperand: SimpleIdentifier
            token: y
        operator: !=
        rightOperand: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_equalityExpression_precedence_relational_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x is y == z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: IsExpression
    expression: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: y
  operator: ==
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_equalityExpression_precedence_relational_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x == y is z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ==
  rightOperand: IsExpression
    expression: SimpleIdentifier
      token: y
    isOperator: is
    type: NamedType
      name: z
''');
  }

  void test_equalityExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super == y != z;
  }
}
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 38, 2),
    ]);

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression: BinaryExpression
        leftOperand: BinaryExpression
          leftOperand: SuperExpression
            superKeyword: super
          operator: ==
          rightOperand: SimpleIdentifier
            token: y
        operator: !=
        rightOperand: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_ifNullExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x ?? y ?? z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ??
    rightOperand: SimpleIdentifier
      token: y
  operator: ??
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_ifNullExpression_precedence_logicalOr_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x || y ?? z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ||
    rightOperand: SimpleIdentifier
      token: y
  operator: ??
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_ifNullExpression_precedence_logicalOr_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x ?? y || z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ??
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: ||
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_logicalAndExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x && y && z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: &&
    rightOperand: SimpleIdentifier
      token: y
  operator: &&
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x | y < z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: |
    rightOperand: SimpleIdentifier
      token: y
  operator: <
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x < y | z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: <
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: |
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_logicalAndExpressionStatement() {
    // Ensure `<` and `>` are parsed as operators, not type arguments.
    var parseResult = parseStringWithErrors(r'''
void f() {
  C<T && T>U;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: C
    operator: <
    rightOperand: SimpleIdentifier
      token: T
  operator: &&
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: T
    operator: >
    rightOperand: SimpleIdentifier
      token: U
''');
  }

  void test_logicalOrExpression() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x || y || z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ||
    rightOperand: SimpleIdentifier
      token: y
  operator: ||
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x && y || z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: &&
    rightOperand: SimpleIdentifier
      token: y
  operator: ||
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x || y && z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ||
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: &&
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_methodInvocation1() {
    // Ensure `<` and `>` in arguments are parsed as operators, not type args.
    var parseResult = parseStringWithErrors(r'''
void f() {
  f(a < b, c > 3);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >
        rightOperand: IntegerLiteral
          literal: 3
    rightParenthesis: )
''');
  }

  void test_methodInvocation2() {
    // Ensure `<` and `>` in arguments are parsed as operators, not type args.
    var parseResult = parseStringWithErrors(r'''
void f() {
  f(a < b, c >> 3);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: >>
        rightOperand: IntegerLiteral
          literal: 3
    rightParenthesis: )
''');
  }

  void test_methodInvocation3() {
    // Ensure `<` and `>` in arguments are parsed as operators, not type args.
    var parseResult = parseStringWithErrors(r'''
void f() {
  f(a < b, c < d >> 3);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: a
        operator: <
        rightOperand: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand: SimpleIdentifier
          token: c
        operator: <
        rightOperand: BinaryExpression
          leftOperand: SimpleIdentifier
            token: d
          operator: >>
          rightOperand: IntegerLiteral
            literal: 3
    rightParenthesis: )
''');
  }

  void test_multipleLabels_statement() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  a: b: c: return x;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleLabeledStatement;
    assertParsedNodeText(node, r'''
LabeledStatement
  labels
    Label
      label: SimpleIdentifier
        token: a
      colon: :
    Label
      label: SimpleIdentifier
        token: b
      colon: :
    Label
      label: SimpleIdentifier
        token: c
      colon: :
  statement: ReturnStatement
    returnKeyword: return
    expression: SimpleIdentifier
      token: x
    semicolon: ;
''');
  }

  void test_multiplicativeExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x * y / z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: *
    rightOperand: SimpleIdentifier
      token: y
  operator: /
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  -x * y;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: PrefixExpression
    operator: -
    operand: SimpleIdentifier
      token: x
  operator: *
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x * -y;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: *
  rightOperand: PrefixExpression
    operator: -
    operand: SimpleIdentifier
      token: y
''');
  }

  void test_multiplicativeExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super * y / z;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: *
    rightOperand: SimpleIdentifier
      token: y
  operator: /
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_relationalExpression_precedence_shift_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x << y is z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
IsExpression
  expression: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: <<
    rightOperand: SimpleIdentifier
      token: y
  isOperator: is
  type: NamedType
    name: z
''');
  }

  void test_shiftExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x >> 4 << 3;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: >>
    rightOperand: IntegerLiteral
      literal: 4
  operator: <<
  rightOperand: IntegerLiteral
    literal: 3
''');
  }

  void test_shiftExpression_precedence_additive_left() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x + y << z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: +
    rightOperand: SimpleIdentifier
      token: y
  operator: <<
  rightOperand: SimpleIdentifier
    token: z
''');
  }

  void test_shiftExpression_precedence_additive_right() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  x << y + z;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: <<
  rightOperand: BinaryExpression
    leftOperand: SimpleIdentifier
      token: y
    operator: +
    rightOperand: SimpleIdentifier
      token: z
''');
  }

  void test_shiftExpression_super() {
    var parseResult = parseStringWithErrors(r'''
class A {
  void f() {
    super >> 4 << 3;
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExpressionStatement.expression;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: SuperExpression
      superKeyword: super
    operator: >>
    rightOperand: IntegerLiteral
      literal: 4
  operator: <<
  rightOperand: IntegerLiteral
    literal: 3
''');
  }

  void test_topLevelFunction_nestedGenericFunction() {
    var parseResult = parseStringWithErrors(r'''
void f() {
  void g<T>() {
  }
}
''');
    parseResult.assertNoErrors();

    var node = parseResult
        .findNode
        .singleFunctionDeclarationStatement
        .functionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  returnType: NamedType
    name: void
  name: g
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }
}
