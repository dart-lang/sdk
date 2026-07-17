// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'simple_parser_test.dart';
library;

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ComplexParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x + y - z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: +
    rightOperand2: SimpleIdentifier
      token: y
  operator: -
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_additiveExpression_noSpaces() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  i+1;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: i
  operator: +
  rightOperand2: IntegerLiteral
    literal: 1
''');
  }

  void test_additiveExpression_precedence_multiplicative_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x * y + z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: *
    rightOperand2: SimpleIdentifier
      token: y
  operator: +
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_additiveExpression_precedence_multiplicative_left_withSuper() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super * y - z;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: *
    rightOperand2: SimpleIdentifier
      token: y
  operator: -
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_additiveExpression_precedence_multiplicative_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x + y * z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: +
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: *
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_additiveExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super + y - z;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: +
    rightOperand2: SimpleIdentifier
      token: y
  operator: -
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_assignableExpression_arguments_normal_chain() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a(b)(c).d(e).f;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
PropertyAccess
  target2: MethodInvocation
    target2: FunctionExpressionInvocation
      function2: MethodInvocation
        methodName: SimpleIdentifier
          token: a
        argumentList: ArgumentList
          leftParenthesis: (
          arguments2
            SimpleIdentifier
              token: b
          rightParenthesis: )
      argumentList: ArgumentList
        leftParenthesis: (
        arguments2
          SimpleIdentifier
            token: c
        rightParenthesis: )
    operator: .
    methodName: SimpleIdentifier
      token: d
    argumentList: ArgumentList
      leftParenthesis: (
      arguments2
        SimpleIdentifier
          token: e
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: f
''');
  }

  void test_assignableExpression_arguments_normal_chain_typeArguments() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a<E>(b)<F>(c).d<G>(e).f;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
PropertyAccess
  target2: MethodInvocation
    target2: FunctionExpressionInvocation
      function2: MethodInvocation
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
          arguments2
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
        arguments2
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
      arguments2
        SimpleIdentifier
          token: e
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: f
''');
  }

  void test_assignmentExpression_compound() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x = y = 0;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: SimpleIdentifier
    token: x
  operator: =
  rightHandSide2: AssignmentExpression
    leftHandSide2: SimpleIdentifier
      token: y
    operator: =
    rightHandSide2: IntegerLiteral
      literal: 0
''');
  }

  void test_assignmentExpression_indexExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x[1] = 0;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: IndexExpression
    target2: SimpleIdentifier
      token: x
    leftBracket: [
    index2: IntegerLiteral
      literal: 1
    rightBracket: ]
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
''');
  }

  void test_assignmentExpression_prefixedIdentifier() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x.y = 0;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
    period: .
    identifier: SimpleIdentifier
      token: y
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
''');
  }

  void test_assignmentExpression_propertyAccess() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super.y = 0;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide2: PropertyAccess
    target2: SuperExpression
      superKeyword: super
    operator: .
    propertyName: SimpleIdentifier
      token: y
  operator: =
  rightHandSide2: IntegerLiteral
    literal: 0
''');
  }

  void test_binary_operator_written_out_expression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x xor y;
//  ^^^
// [diag.expectedToken] Expected to find ';'.
}
''');

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
      expression2: SimpleIdentifier
        token: y
      semicolon: ;
  rightBracket: }
''');
  }

  void test_binary_operator_written_out_expression_logical() {
    // Report `and` and recover with a synthetic `&&` in the parsed AST.
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x > 0 and y > 1;
//      ^^^
// [diag.binaryOperatorWrittenOut] Binary operator 'and' is written as '&&' instead of the written out word.
}
''');

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: BinaryExpression
        leftOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: x
          operator: >
          rightOperand2: IntegerLiteral
            literal: 0
        operator: && <synthetic>
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: y
          operator: >
          rightOperand2: IntegerLiteral
            literal: 1
      semicolon: ;
  rightBracket: }
''');
  }

  void test_bitwiseAndExpression_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x & y & z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: &
    rightOperand2: SimpleIdentifier
      token: y
  operator: &
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseAndExpression_precedence_equality_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x == y && z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: ==
    rightOperand2: SimpleIdentifier
      token: y
  operator: &&
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseAndExpression_precedence_equality_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x && y == z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: &&
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: ==
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_bitwiseAndExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super & y & z;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: &
    rightOperand2: SimpleIdentifier
      token: y
  operator: &
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseOrExpression_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x | y | z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: |
    rightOperand2: SimpleIdentifier
      token: y
  operator: |
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseOrExpression_precedence_xor_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x ^ y | z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: ^
    rightOperand2: SimpleIdentifier
      token: y
  operator: |
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseOrExpression_precedence_xor_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x | y ^ z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: |
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: ^
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_bitwiseOrExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super | y | z;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: |
    rightOperand2: SimpleIdentifier
      token: y
  operator: |
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseXorExpression_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x ^ y ^ z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: ^
    rightOperand2: SimpleIdentifier
      token: y
  operator: ^
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseXorExpression_precedence_and_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x & y ^ z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: &
    rightOperand2: SimpleIdentifier
      token: y
  operator: ^
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_bitwiseXorExpression_precedence_and_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x ^ y & z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: ^
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: &
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_bitwiseXorExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super ^ y ^ z;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: ^
    rightOperand2: SimpleIdentifier
      token: y
  operator: ^
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_cascade_withAssignment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  new Map()..[3] = 4 ..[0] = 11;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
CascadeExpression
  target2: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: Map
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
  cascadeSections2
    AssignmentExpression
      leftHandSide2: IndexExpression
        period: ..
        leftBracket: [
        index2: IntegerLiteral
          literal: 3
        rightBracket: ]
      operator: =
      rightHandSide2: IntegerLiteral
        literal: 4
    AssignmentExpression
      leftHandSide2: IndexExpression
        period: ..
        leftBracket: [
        index2: IntegerLiteral
          literal: 0
        rightBracket: ]
      operator: =
      rightHandSide2: IntegerLiteral
        literal: 11
''');
  }

  void test_conditionalExpression_precedence_ifNullExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a ?? b ? y : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: a
    operator: ??
    rightOperand2: SimpleIdentifier
      token: b
  question: ?
  thenExpression2: SimpleIdentifier
    token: y
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_logicalOrExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a | b ? y : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: a
    operator: |
    rightOperand2: SimpleIdentifier
      token: b
  question: ?
  thenExpression2: SimpleIdentifier
    token: y
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_as() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x as bool ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: AsExpression
    expression2: SimpleIdentifier
      token: x
    asOperator: as
    type: NamedType
      name: bool
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_as2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x as bool? ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: AsExpression
    expression2: SimpleIdentifier
      token: x
    asOperator: as
    type: NamedType
      name: bool
      question: ?
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_as3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  (x as bool?) ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: ParenthesizedExpression
    leftParenthesis: (
    expression2: AsExpression
      expression2: SimpleIdentifier
        token: x
      asOperator: as
      type: NamedType
        name: bool
        question: ?
    rightParenthesis: )
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_is() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is String ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: IsExpression
    expression2: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: String
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_is2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is String? ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: IsExpression
    expression2: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: String
      question: ?
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableType_is3() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  (x is String?) ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: ParenthesizedExpression
    leftParenthesis: (
    expression2: IsExpression
      expression2: SimpleIdentifier
        token: x
      isOperator: is
      type: NamedType
        name: String
        question: ?
    rightParenthesis: )
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1_is() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is String<S> ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: IsExpression
    expression2: SimpleIdentifier
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
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg1GFT_is() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is String<S> Function() ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: IsExpression
    expression2: SimpleIdentifier
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
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_nullableTypeWithTypeArg2_is() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is String<S,T> ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: IsExpression
    expression2: SimpleIdentifier
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
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_prefixedNullableType_is() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is p.A ? (x + y) : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: IsExpression
    expression2: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
      name: A
  question: ?
  thenExpression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: BinaryExpression
      leftOperand2: SimpleIdentifier
        token: x
      operator: +
      rightOperand2: SimpleIdentifier
        token: y
    rightParenthesis: )
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_precedence_withAssignment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  b ? c = true : g();
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: SimpleIdentifier
    token: b
  question: ?
  thenExpression2: AssignmentExpression
    leftHandSide2: SimpleIdentifier
      token: c
    operator: =
    rightHandSide2: BooleanLiteral
      literal: true
  colon: :
  elseExpression2: MethodInvocation
    methodName: SimpleIdentifier
      token: g
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_conditionalExpression_precedence_withAssignment2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  b.x ? c = true : g();
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: b
    period: .
    identifier: SimpleIdentifier
      token: x
  question: ?
  thenExpression2: AssignmentExpression
    leftHandSide2: SimpleIdentifier
      token: c
    operator: =
    rightHandSide2: BooleanLiteral
      literal: true
  colon: :
  elseExpression2: MethodInvocation
    methodName: SimpleIdentifier
      token: g
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
''');
  }

  void test_conditionalExpression_prefixedValue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a.b ? y : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
    period: .
    identifier: SimpleIdentifier
      token: b
  question: ?
  thenExpression2: SimpleIdentifier
    token: y
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_conditionalExpression_prefixedValue2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a.b ? x.y : z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: a
    period: .
    identifier: SimpleIdentifier
      token: b
  question: ?
  thenExpression2: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: x
    period: .
    identifier: SimpleIdentifier
      token: y
  colon: :
  elseExpression2: SimpleIdentifier
    token: z
''');
  }

  void test_constructor_initializer_withParenthesizedExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class C {
  C() : this.a = (b == null ? c : d);
}
''');

    var node = parseResult.findNode.singleConstructorFieldInitializer;
    assertParsedNodeText(node, r'''
ConstructorFieldInitializer
  thisKeyword: this
  period: .
  fieldName: SimpleIdentifier
    token: a
  equals: =
  expression2: ParenthesizedExpression
    leftParenthesis: (
    expression2: ConditionalExpression
      condition2: BinaryExpression
        leftOperand2: SimpleIdentifier
          token: b
        operator: ==
        rightOperand2: NullLiteral
          literal: null
      question: ?
      thenExpression2: SimpleIdentifier
        token: c
      colon: :
      elseExpression2: SimpleIdentifier
        token: d
    rightParenthesis: )
''');
  }

  void test_equalityExpression_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x == y != z;
//       ^^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
}
''');

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: BinaryExpression
        leftOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: x
          operator: ==
          rightOperand2: SimpleIdentifier
            token: y
        operator: !=
        rightOperand2: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_equalityExpression_precedence_relational_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x is y == z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: IsExpression
    expression2: SimpleIdentifier
      token: x
    isOperator: is
    type: NamedType
      name: y
  operator: ==
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_equalityExpression_precedence_relational_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x == y is z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: ==
  rightOperand2: IsExpression
    expression2: SimpleIdentifier
      token: y
    isOperator: is
    type: NamedType
      name: z
''');
  }

  void test_equalityExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super == y != z;
//             ^^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
  }
}
''');

    var node = parseResult.findNode.singleBlock;
    assertParsedNodeText(node, r'''
Block
  leftBracket: {
  statements
    ExpressionStatement
      expression2: BinaryExpression
        leftOperand2: BinaryExpression
          leftOperand2: SuperExpression
            superKeyword: super
          operator: ==
          rightOperand2: SimpleIdentifier
            token: y
        operator: !=
        rightOperand2: SimpleIdentifier
          token: z
      semicolon: ;
  rightBracket: }
''');
  }

  void test_ifNullExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x ?? y ?? z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: ??
    rightOperand2: SimpleIdentifier
      token: y
  operator: ??
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_ifNullExpression_precedence_logicalOr_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x || y ?? z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: ||
    rightOperand2: SimpleIdentifier
      token: y
  operator: ??
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_ifNullExpression_precedence_logicalOr_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x ?? y || z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: ??
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: ||
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_logicalAndExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x && y && z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: &&
    rightOperand2: SimpleIdentifier
      token: y
  operator: &&
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_logicalAndExpression_precedence_bitwiseOr_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x | y < z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: |
    rightOperand2: SimpleIdentifier
      token: y
  operator: <
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_logicalAndExpression_precedence_bitwiseOr_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x < y | z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: <
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: |
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_logicalAndExpressionStatement() {
    // Ensure `<` and `>` are parsed as operators, not type arguments.
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  C<T && T>U;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: C
    operator: <
    rightOperand2: SimpleIdentifier
      token: T
  operator: &&
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: T
    operator: >
    rightOperand2: SimpleIdentifier
      token: U
''');
  }

  void test_logicalOrExpression() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x || y || z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: ||
    rightOperand2: SimpleIdentifier
      token: y
  operator: ||
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_logicalOrExpression_precedence_logicalAnd_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x && y || z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: &&
    rightOperand2: SimpleIdentifier
      token: y
  operator: ||
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_logicalOrExpression_precedence_logicalAnd_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x || y && z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: ||
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: &&
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_methodInvocation1() {
    // Ensure `<` and `>` in arguments are parsed as operators, not type args.
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  f(a < b, c > 3);
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >
        rightOperand2: IntegerLiteral
          literal: 3
    rightParenthesis: )
''');
  }

  void test_methodInvocation2() {
    // Ensure `<` and `>` in arguments are parsed as operators, not type args.
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  f(a < b, c >> 3);
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: >>
        rightOperand2: IntegerLiteral
          literal: 3
    rightParenthesis: )
''');
  }

  void test_methodInvocation3() {
    // Ensure `<` and `>` in arguments are parsed as operators, not type args.
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  f(a < b, c < d >> 3);
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: f
  argumentList: ArgumentList
    leftParenthesis: (
    arguments2
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: a
        operator: <
        rightOperand2: SimpleIdentifier
          token: b
      BinaryExpression
        leftOperand2: SimpleIdentifier
          token: c
        operator: <
        rightOperand2: BinaryExpression
          leftOperand2: SimpleIdentifier
            token: d
          operator: >>
          rightOperand2: IntegerLiteral
            literal: 3
    rightParenthesis: )
''');
  }

  void test_multipleLabels_statement() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  a: b: c: return x;
}
''');

    var node = parseResult.findNode.singleLabeledStatement;
    assertParsedNodeText(node, r'''
LabeledStatement
  labels
    Label
      name: a
      colon: :
    Label
      name: b
      colon: :
    Label
      name: c
      colon: :
  statement: ReturnStatement
    returnKeyword: return
    expression2: SimpleIdentifier
      token: x
    semicolon: ;
''');
  }

  void test_multiplicativeExpression_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x * y / z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: *
    rightOperand2: SimpleIdentifier
      token: y
  operator: /
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_multiplicativeExpression_precedence_unary_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  -x * y;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: PrefixExpression
    operator: -
    operand2: SimpleIdentifier
      token: x
  operator: *
  rightOperand2: SimpleIdentifier
    token: y
''');
  }

  void test_multiplicativeExpression_precedence_unary_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x * -y;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: *
  rightOperand2: PrefixExpression
    operator: -
    operand2: SimpleIdentifier
      token: y
''');
  }

  void test_multiplicativeExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super * y / z;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: *
    rightOperand2: SimpleIdentifier
      token: y
  operator: /
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_relationalExpression_precedence_shift_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x << y is z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
IsExpression
  expression2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: <<
    rightOperand2: SimpleIdentifier
      token: y
  isOperator: is
  type: NamedType
    name: z
''');
  }

  void test_shiftExpression_normal() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x >> 4 << 3;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: >>
    rightOperand2: IntegerLiteral
      literal: 4
  operator: <<
  rightOperand2: IntegerLiteral
    literal: 3
''');
  }

  void test_shiftExpression_precedence_additive_left() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x + y << z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: x
    operator: +
    rightOperand2: SimpleIdentifier
      token: y
  operator: <<
  rightOperand2: SimpleIdentifier
    token: z
''');
  }

  void test_shiftExpression_precedence_additive_right() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  x << y + z;
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: SimpleIdentifier
    token: x
  operator: <<
  rightOperand2: BinaryExpression
    leftOperand2: SimpleIdentifier
      token: y
    operator: +
    rightOperand2: SimpleIdentifier
      token: z
''');
  }

  void test_shiftExpression_super() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
class A {
  void f() {
    super >> 4 << 3;
  }
}
''');

    var node = parseResult.findNode.singleExpressionStatement.expression2;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand2: BinaryExpression
    leftOperand2: SuperExpression
      superKeyword: super
    operator: >>
    rightOperand2: IntegerLiteral
      literal: 4
  operator: <<
  rightOperand2: IntegerLiteral
    literal: 3
''');
  }

  void test_topLevelFunction_nestedGenericFunction() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
void f() {
  void g<T>() {
  }
}
''');

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
