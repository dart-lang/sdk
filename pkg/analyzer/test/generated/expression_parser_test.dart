// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../src/dart/resolution/node_text_expectations.dart';
import '../src/diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExpressionParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExpressionParserTest extends ParserDiagnosticsTest {
  void test_binaryExpression_allOperators() {
    // https://github.com/dart-lang/sdk/issues/36255
    for (TokenType type in TokenType.all) {
      if (type.precedence > 0) {
        var source = 'a ${type.lexeme} b';
        try {
          parseStringWithErrors('var x = $source;');
        } on TestFailure {
          // Ensure that there are no infinite loops or exceptions thrown
          // by the parser. Test failures are fine.
        }
      }
    }
  }

  void test_invalidExpression_37706() {
    var parseResult = parseStringWithErrors(r'''
var v = <b?c>();
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 1),
      error(diag.unexpectedToken, 15, 1),
      error(diag.missingFunctionBody, 15, 1),
      error(diag.expectedToken, 15, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: FunctionExpression
              typeParameters: TypeParameterList
                leftBracket: <
                typeParameters
                  TypeParameter
                    name: b
                rightBracket: >
              parameters: FormalParameterList
                leftParenthesis: (
                rightParenthesis: )
              body: EmptyFunctionBody
                semicolon: ;
      semicolon: ; <synthetic>
''');
  }

  void test_listLiteral_invalid_assert() {
    var parseResult = parseStringWithErrors(r'''
var v = n=<.["$assert;
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 11, 1),
      error(diag.expectedTypeName, 12, 1),
      error(diag.expectedIdentifierButGotKeyword, 15, 6),
      error(diag.unterminatedStringLiteral, 21, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 23, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: AssignmentExpression
              leftHandSide: SimpleIdentifier
                token: n
              operator: =
              rightHandSide: ListLiteral
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      importPrefix: ImportPrefixReference
                        name: <empty> <synthetic>
                        period: .
                      name: <empty> <synthetic>
                  rightBracket: > <synthetic>
                leftBracket: [
                elements
                  StringInterpolation
                    elements
                      InterpolationString
                        contents: "
                      InterpolationExpression
                        leftBracket: $
                        expression: SimpleIdentifier
                          token: assert
                      InterpolationString
                        contents: ;" <synthetic>
                    stringValue: null
                rightBracket: ] <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_listLiteral_invalidElement_37697() {
    var parseResult = parseStringWithErrors(r'''
var v = [<y.<z>(){}];
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 12, 1),
      error(diag.expectedToken, 14, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                SetOrMapLiteral
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        importPrefix: ImportPrefixReference
                          name: y
                          period: .
                        name: <empty> <synthetic>
                        typeArguments: TypeArgumentList
                          leftBracket: <
                          arguments
                            NamedType
                              name: z
                          rightBracket: >
                    rightBracket: > <synthetic>
                  leftBracket: {
                  rightBracket: }
                  isMap: false
              rightBracket: ]
      semicolon: ;
''');
  }

  void test_lt_dot_bracket_quote() {
    var parseResult = parseStringWithErrors(r'''
var v = <.[";
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 9, 1),
      error(diag.expectedTypeName, 10, 1),
      error(diag.expectedToken, 11, 2),
      error(diag.unterminatedStringLiteral, 12, 1),
      error(diag.expectedToken, 14, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        importPrefix: ImportPrefixReference
          name: <empty> <synthetic>
          period: .
        name: <empty> <synthetic>
    rightBracket: > <synthetic>
  leftBracket: [
  elements
    SimpleStringLiteral
      literal: ";" <synthetic>
  rightBracket: ] <synthetic>
''');
  }

  void test_lt_dot_listLiteral() {
    var parseResult = parseStringWithErrors(r'''
var v = <.[];
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 9, 1),
      error(diag.expectedTypeName, 10, 2),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        importPrefix: ImportPrefixReference
          name: <empty> <synthetic>
          period: .
        name: <empty> <synthetic>
    rightBracket: > <synthetic>
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_mapLiteral() {
    var parseResult = parseStringWithErrors(r'''
var v = {3: 6};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 3
      separator: :
      value: IntegerLiteral
        literal: 6
  rightBracket: }
  isMap: false
''');
  }

  void test_mapLiteral_const() {
    var parseResult = parseStringWithErrors(r'''
var v = const {3: 6};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  constKeyword: const
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 3
      separator: :
      value: IntegerLiteral
        literal: 6
  rightBracket: }
  isMap: false
''');
  }

  @failingTest
  void test_mapLiteral_invalid_too_many_type_arguments1() {
    var parseResult = parseStringWithErrors(r'''
var v = <int, int, int>{};
''');
    parseResult.assertErrors([error(diag.expectedToken, 11, 3)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
''');
  }

  @failingTest
  void test_mapLiteral_invalid_too_many_type_arguments2() {
    var parseResult = parseStringWithErrors(r'''
var v = <int, int, int>{1};
''');
    parseResult.assertErrors([error(diag.expectedToken, 11, 3)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
''');
  }

  void test_namedArgument() {
    var parseResult = parseStringWithErrors(r'''
var v = m(a: 1, b: 2);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: m
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: a
          colon: :
        expression: IntegerLiteral
          literal: 1
      NamedExpression
        name: Label
          label: SimpleIdentifier
            token: b
          colon: :
        expression: IntegerLiteral
          literal: 2
    rightParenthesis: )
''');
  }

  void test_nullableTypeInStringInterpolations_as_48999() {
    var parseResult = parseStringWithErrors(r'''
var v = ${i as int?};
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 9, 1),
      error(diag.unexpectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $
''');
  }

  void test_nullableTypeInStringInterpolations_is_48999() {
    var parseResult = parseStringWithErrors(r'''
var v = ${i is int?};
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 9, 1),
      error(diag.unexpectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $
''');
  }

  void test_parseAdditiveExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x + y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: +
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseAdditiveExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super + y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: +
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseAssignableExpression_expression_args_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = (x)(y).z;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
      rightParenthesis: )
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: y
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: z
''');
  }

  void test_parseAssignableExpression_expression_args_dot_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = (x)<F>(y).z;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: FunctionExpressionInvocation
    function: ParenthesizedExpression
      leftParenthesis: (
      expression: SimpleIdentifier
        token: x
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
          token: y
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: z
''');
  }

  void test_parseAssignableExpression_expression_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = (x).y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
    rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: y
''');
  }

  void test_parseAssignableExpression_expression_index() {
    var parseResult = parseStringWithErrors(r'''
var v = (x)[y];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
    rightParenthesis: )
  leftBracket: [
  index: SimpleIdentifier
    token: y
  rightBracket: ]
''');
  }

  void test_parseAssignableExpression_expression_question_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = (x)?.y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: ParenthesizedExpression
    leftParenthesis: (
    expression: SimpleIdentifier
      token: x
    rightParenthesis: )
  operator: ?.
  propertyName: SimpleIdentifier
    token: y
''');
  }

  void test_parseAssignableExpression_identifier() {
    var parseResult = parseStringWithErrors(r'''
var v = x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: x
''');
  }

  void test_parseAssignableExpression_identifier_args_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = x(y).z;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: MethodInvocation
    methodName: SimpleIdentifier
      token: x
    argumentList: ArgumentList
      leftParenthesis: (
      arguments
        SimpleIdentifier
          token: y
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: z
''');
  }

  void test_parseAssignableExpression_identifier_args_dot_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = x<E>(y).z;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: MethodInvocation
    methodName: SimpleIdentifier
      token: x
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
          token: y
      rightParenthesis: )
  operator: .
  propertyName: SimpleIdentifier
    token: z
''');
  }

  void test_parseAssignableExpression_identifier_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = x.y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
  period: .
  identifier: SimpleIdentifier
    token: y
''');
  }

  void test_parseAssignableExpression_identifier_index() {
    var parseResult = parseStringWithErrors(r'''
var v = x[y];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: x
  leftBracket: [
  index: SimpleIdentifier
    token: y
  rightBracket: ]
''');
  }

  void test_parseAssignableExpression_identifier_question_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = x?.y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: x
  operator: ?.
  propertyName: SimpleIdentifier
    token: y
''');
  }

  void test_parseAssignableExpression_super_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = super.y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
  operator: .
  propertyName: SimpleIdentifier
    token: y
''');
  }

  void test_parseAssignableExpression_super_index() {
    var parseResult = parseStringWithErrors(r'''
var v = super[y];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: SuperExpression
    superKeyword: super
  leftBracket: [
  index: SimpleIdentifier
    token: y
  rightBracket: ]
''');
  }

  void test_parseAssignableSelector_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = x.x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: x
  period: .
  identifier: SimpleIdentifier
    token: x
''');
  }

  void test_parseAssignableSelector_index() {
    var parseResult = parseStringWithErrors(r'''
var v = x[x];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: x
  leftBracket: [
  index: SimpleIdentifier
    token: x
  rightBracket: ]
''');
  }

  void test_parseAssignableSelector_none() {
    var parseResult = parseStringWithErrors(r'''
var v = x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: x
''');
  }

  void test_parseAssignableSelector_question_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = x?.x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: SimpleIdentifier
    token: x
  operator: ?.
  propertyName: SimpleIdentifier
    token: x
''');
  }

  void test_parseAwaitExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = await x;
''');
    parseResult.assertErrors([error(diag.awaitInWrongContext, 8, 5)]);
    var node = parseResult.findNode.singleAwaitExpression;
    assertParsedNodeText(node, r'''
AwaitExpression
  awaitKeyword: await
  expression: SimpleIdentifier
    token: x
''');
  }

  void test_parseBitwiseAndExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x & y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: &
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseBitwiseAndExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super & y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: &
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseBitwiseOrExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x | y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: |
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseBitwiseOrExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super | y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: |
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseBitwiseXorExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x ^ y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ^
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseBitwiseXorExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super ^ y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: ^
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseCascadeSection_i() {
    var parseResult = parseStringWithErrors(r'''
var v = null..[i];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    IndexExpression
      period: ..
      leftBracket: [
      index: SimpleIdentifier
        token: i
      rightBracket: ]
''');
  }

  void test_parseCascadeSection_ia() {
    var parseResult = parseStringWithErrors(r'''
var v = null..[i](b);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    FunctionExpressionInvocation
      function: IndexExpression
        period: ..
        leftBracket: [
        index: SimpleIdentifier
          token: i
        rightBracket: ]
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: b
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_ia_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null..[i]<E>(b);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    FunctionExpressionInvocation
      function: IndexExpression
        period: ..
        leftBracket: [
        index: SimpleIdentifier
          token: i
        rightBracket: ]
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
''');
  }

  void test_parseCascadeSection_ii() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a(b).c(d);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    MethodInvocation
      target: MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: a
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: b
          rightParenthesis: )
      operator: .
      methodName: SimpleIdentifier
        token: c
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: d
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_ii_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a<E>(b).c<F>(d);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    MethodInvocation
      target: MethodInvocation
        operator: ..
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
      operator: .
      methodName: SimpleIdentifier
        token: c
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
            token: d
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_p() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: a
''');
  }

  void test_parseCascadeSection_p_assign() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a = 3;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    AssignmentExpression
      leftHandSide: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: a
      operator: =
      rightHandSide: IntegerLiteral
        literal: 3
''');
  }

  void test_parseCascadeSection_p_assign_withCascade() {
    var parseResult = parseStringWithErrors(r'''
var v = null
  ..a = 3
  ..m();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    AssignmentExpression
      leftHandSide: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: a
      operator: =
      rightHandSide: IntegerLiteral
        literal: 3
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: m
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_p_assign_withCascade_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null
  ..a = 3
  ..m<E>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    AssignmentExpression
      leftHandSide: PropertyAccess
        operator: ..
        propertyName: SimpleIdentifier
          token: a
      operator: =
      rightHandSide: IntegerLiteral
        literal: 3
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: m
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: E
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_p_builtIn() {
    var parseResult = parseStringWithErrors(r'''
var v = null..as;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    PropertyAccess
      operator: ..
      propertyName: SimpleIdentifier
        token: as
''');
  }

  void test_parseCascadeSection_pa() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a(b);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    MethodInvocation
      operator: ..
      methodName: SimpleIdentifier
        token: a
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: b
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_pa_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a<E>(b);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    MethodInvocation
      operator: ..
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
''');
  }

  void test_parseCascadeSection_paa() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a(b)(c);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    FunctionExpressionInvocation
      function: MethodInvocation
        operator: ..
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
''');
  }

  void test_parseCascadeSection_paa_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a<E>(b)<F>(c);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    FunctionExpressionInvocation
      function: MethodInvocation
        operator: ..
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
''');
  }

  void test_parseCascadeSection_paapaa() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a(b)(c).d(e)(f);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    FunctionExpressionInvocation
      function: MethodInvocation
        target: FunctionExpressionInvocation
          function: MethodInvocation
            operator: ..
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
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: f
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_paapaa_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a<E>(b)<F>(c).d<G>(e)<H>(f);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    FunctionExpressionInvocation
      function: MethodInvocation
        target: FunctionExpressionInvocation
          function: MethodInvocation
            operator: ..
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
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: H
        rightBracket: >
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          SimpleIdentifier
            token: f
        rightParenthesis: )
''');
  }

  void test_parseCascadeSection_pap() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a(b).c;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    PropertyAccess
      target: MethodInvocation
        operator: ..
        methodName: SimpleIdentifier
          token: a
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            SimpleIdentifier
              token: b
          rightParenthesis: )
      operator: .
      propertyName: SimpleIdentifier
        token: c
''');
  }

  void test_parseCascadeSection_pap_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = null..a<E>(b).c;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
CascadeExpression
  target: NullLiteral
    literal: null
  cascadeSections
    PropertyAccess
      target: MethodInvocation
        operator: ..
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
      operator: .
      propertyName: SimpleIdentifier
        token: c
''');
  }

  void test_parseConditionalExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = x ? y : z;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ConditionalExpression
  condition: SimpleIdentifier
    token: x
  question: ?
  thenExpression: SimpleIdentifier
    token: y
  colon: :
  elseExpression: SimpleIdentifier
    token: z
''');
  }

  void test_parseConstExpression_instanceCreation() {
    var parseResult = parseStringWithErrors(r'''
var v = const A();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: const
  constructorName: ConstructorName
    type: NamedType
      name: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseConstExpression_listLiteral_typed() {
    var parseResult = parseStringWithErrors(r'''
var v = const <A>[];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  constKeyword: const
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: A
    rightBracket: >
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parseConstExpression_listLiteral_untyped() {
    var parseResult = parseStringWithErrors(r'''
var v = const [];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  constKeyword: const
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parseConstExpression_mapLiteral_typed() {
    var parseResult = parseStringWithErrors(r'''
var v = const <A, B>{};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  constKeyword: const
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: A
      NamedType
        name: B
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: false
''');
  }

  void test_parseConstExpression_mapLiteral_typed_missingGt() {
    var parseResult = parseStringWithErrors(r'''
var v = const <A, B {};
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  constKeyword: const
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: A
      NamedType
        name: B
    rightBracket: > <synthetic>
  leftBracket: {
  rightBracket: }
  isMap: false
''');
  }

  void test_parseConstExpression_mapLiteral_untyped() {
    var parseResult = parseStringWithErrors(r'''
var v = const {};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  constKeyword: const
  leftBracket: {
  rightBracket: }
  isMap: false
''');
  }

  void test_parseConstructorInitializer_functionExpression() {
    var parseResult = parseStringWithErrors(r'''
class C { C.n() : this()(); }
''');
    parseResult.assertErrors([error(diag.invalidInitializer, 18, 8)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            period: .
            name: n
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseEqualityExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x == y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ==
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseEqualityExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super == y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: ==
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseExpression_assign() {
    var parseResult = parseStringWithErrors(r'''
var v = x = y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
''');
  }

  void test_parseExpression_assign_compound() {
    var parseResult = parseStringWithErrors(r'''
var v = x ||= y;
''');
    parseResult.assertErrors([
      error(diag.missingAssignableSelector, 8, 4),
      error(diag.missingIdentifier, 12, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: BinaryExpression
    leftOperand: SimpleIdentifier
      token: x
    operator: ||
    rightOperand: SimpleIdentifier
      token: <empty> <synthetic>
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
''');
  }

  void test_parseExpression_comparison() {
    var parseResult = parseStringWithErrors(r'''
var v = --a.b == c;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: PrefixExpression
    operator: --
    operand: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
  operator: ==
  rightOperand: SimpleIdentifier
    token: c
''');
  }

  void test_parseExpression_constAndTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
var v = const <E>;
''');
    parseResult.assertErrors([error(diag.expectedToken, 17, 1)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  constKeyword: const
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: E
    rightBracket: >
  leftBracket: [ <synthetic>
  rightBracket: ] <synthetic>
''');
  }

  void test_parseExpression_function_async() {
    var parseResult = parseStringWithErrors(r'''
var v = () async {};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: async
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseExpression_function_asyncStar() {
    var parseResult = parseStringWithErrors(r'''
var v = () async* {};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: async
    star: *
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseExpression_function_sync() {
    var parseResult = parseStringWithErrors(r'''
var v = () {};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseExpression_function_syncStar() {
    var parseResult = parseStringWithErrors(r'''
var v = () sync* {};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    keyword: sync
    star: *
    block: Block
      leftBracket: {
      rightBracket: }
''');
  }

  void test_parseExpression_invokeFunctionExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = (a) {
  return a + a;
}(3);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpressionInvocation
  function: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: a
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
              operator: +
              rightOperand: SimpleIdentifier
                token: a
            semicolon: ;
        rightBracket: }
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
    rightParenthesis: )
''');
  }

  void test_parseExpression_nonAwait() {
    var parseResult = parseStringWithErrors(r'''
var v = await();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  methodName: SimpleIdentifier
    token: await
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseExpression_sendWithTypeParam_afterIndex() {
    var parseResult = parseStringWithErrors(r'''
main() {
  factories[C]<num, int>();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: FunctionExpressionInvocation
                  function: IndexExpression
                    target: SimpleIdentifier
                      token: factories
                    leftBracket: [
                    index: SimpleIdentifier
                      token: C
                    rightBracket: ]
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: num
                      NamedType
                        name: int
                    rightBracket: >
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_parseExpression_sendWithTypeParam_afterSend() {
    var parseResult = parseStringWithErrors(r'''
main() {
  factories(C)<num, int>();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: main
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: FunctionExpressionInvocation
                  function: MethodInvocation
                    methodName: SimpleIdentifier
                      token: factories
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        SimpleIdentifier
                          token: C
                      rightParenthesis: )
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: num
                      NamedType
                        name: int
                    rightBracket: >
                  argumentList: ArgumentList
                    leftParenthesis: (
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_parseExpression_superMethodInvocation() {
    var parseResult = parseStringWithErrors(r'''
var v = super.m();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
  operator: .
  methodName: SimpleIdentifier
    token: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseExpression_superMethodInvocation_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = super.m<E>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
  operator: .
  methodName: SimpleIdentifier
    token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: E
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseExpression_superMethodInvocation_typeArguments_chained() {
    var parseResult = parseStringWithErrors(r'''
var v = super.b.c<D>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: PropertyAccess
    target: SuperExpression
      superKeyword: super
    operator: .
    propertyName: SimpleIdentifier
      token: b
  operator: .
  methodName: SimpleIdentifier
    token: c
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: D
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseExpressionList_multiple() {
    var parseResult = parseStringWithErrors(r'''
var v = [1, 2, 3];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IntegerLiteral
      literal: 2
    IntegerLiteral
      literal: 3
  rightBracket: ]
''');
  }

  void test_parseExpressionList_single() {
    var parseResult = parseStringWithErrors(r'''
var v = [1];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
  rightBracket: ]
''');
  }

  void test_parseExpressionWithoutCascade_assign() {
    var parseResult = parseStringWithErrors(r'''
var v = x = y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AssignmentExpression
  leftHandSide: SimpleIdentifier
    token: x
  operator: =
  rightHandSide: SimpleIdentifier
    token: y
''');
  }

  void test_parseExpressionWithoutCascade_comparison() {
    var parseResult = parseStringWithErrors(r'''
var v = --a.b == c;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: PrefixExpression
    operator: --
    operand: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: a
      period: .
      identifier: SimpleIdentifier
        token: b
  operator: ==
  rightOperand: SimpleIdentifier
    token: c
''');
  }

  void test_parseExpressionWithoutCascade_superMethodInvocation() {
    var parseResult = parseStringWithErrors(r'''
var v = super.m();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
  operator: .
  methodName: SimpleIdentifier
    token: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_parseExpressionWithoutCascade_superMethodInvocation_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = super.m<E>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SuperExpression
    superKeyword: super
  operator: .
  methodName: SimpleIdentifier
    token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: E
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseFunctionExpression_body_inExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = (int i) => i++;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: i
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: PostfixExpression
      operand: SimpleIdentifier
        token: i
      operator: ++
''');
  }

  void test_parseFunctionExpression_constAndTypeParameters2() {
    var parseResult = parseStringWithErrors(r'''
var v = const <E>(E i) => i++;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 8, 5)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: E
      name: i
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: PostfixExpression
      operand: SimpleIdentifier
        token: i
      operator: ++
''');
  }

  void test_parseFunctionExpression_functionInPlaceOfTypeName() {
    var parseResult = parseStringWithErrors(r'''
var v = <test(, (){});>[0, 1, 2];
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 4)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: test
    rightBracket: >
  leftBracket: [
  elements
    IntegerLiteral
      literal: 0
    IntegerLiteral
      literal: 1
    IntegerLiteral
      literal: 2
  rightBracket: ]
''');
  }

  void test_parseFunctionExpression_typeParameters() {
    var parseResult = parseStringWithErrors(r'''
var v = <E>(E i) => i++;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: E
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: E
      name: i
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: PostfixExpression
      operand: SimpleIdentifier
        token: i
      operator: ++
''');
  }

  void test_parseInstanceCreationExpression_qualifiedType() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseInstanceCreationExpression_qualifiedType_named() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void
  test_parseInstanceCreationExpression_qualifiedType_named_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseInstanceCreationExpression_qualifiedType_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseInstanceCreationExpression_type() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseInstanceCreationExpression_type_named() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseInstanceCreationExpression_type_named_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseInstanceCreationExpression_type_named_typeArguments_34403() {
    var parseResult = parseStringWithErrors(r'''
var v = new a.b.c<C>();
''');
    parseResult.assertErrors([error(diag.constructorWithTypeArguments, 16, 1)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: a
        period: .
      name: b
    period: .
    name: SimpleIdentifier
      token: c
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: C
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parseInstanceCreationExpression_type_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = new $token;
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 6)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: $token
  argumentList: ArgumentList
    leftParenthesis: ( <synthetic>
    rightParenthesis: ) <synthetic>
''');
  }

  void test_parseListLiteral_empty_oneToken() {
    var parseResult = parseStringWithErrors(r'''
var v = [];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parseListLiteral_empty_oneToken_withComment() {
    var parseResult = parseStringWithErrors(r'''
var v = /* 0 */ [];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parseListLiteral_empty_twoTokens() {
    var parseResult = parseStringWithErrors(r'''
var v = [];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parseListLiteral_multiple() {
    var parseResult = parseStringWithErrors(r'''
var v = [1, 2, 3];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
    IntegerLiteral
      literal: 2
    IntegerLiteral
      literal: 3
  rightBracket: ]
''');
  }

  void test_parseListLiteral_single() {
    var parseResult = parseStringWithErrors(r'''
var v = [1];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
  rightBracket: ]
''');
  }

  void test_parseListLiteral_single_withTypeArgument() {
    var parseResult = parseStringWithErrors(r'''
var v = <int>[1];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: [
  elements
    IntegerLiteral
      literal: 1
  rightBracket: ]
''');
  }

  void test_parseListOrMapLiteral_list_noType() {
    var parseResult = parseStringWithErrors(r'''
var v = [1][1];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: ListLiteral
    leftBracket: [
    elements
      IntegerLiteral
        literal: 1
    rightBracket: ]
  leftBracket: [
  index: IntegerLiteral
    literal: 1
  rightBracket: ]
''');
  }

  void test_parseListOrMapLiteral_list_type() {
    var parseResult = parseStringWithErrors(r'''
var v = <int> [1] <int> [1];
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 22, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: BinaryExpression
    leftOperand: ListLiteral
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
        rightBracket: >
      leftBracket: [
      elements
        IntegerLiteral
          literal: 1
      rightBracket: ]
    operator: <
    rightOperand: SimpleIdentifier
      token: int
  operator: >
  rightOperand: ListLiteral
    leftBracket: [
    elements
      IntegerLiteral
        literal: 1
    rightBracket: ]
''');
  }

  void test_parseListOrMapLiteral_map_noType() {
    var parseResult = parseStringWithErrors(r'''
var v = {'1' : 1} {'1' : 1};
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedExecutable, 18, 1),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: SimpleStringLiteral
        literal: '1'
      separator: :
      value: IntegerLiteral
        literal: 1
  rightBracket: }
  isMap: false
''');
  }

  void test_parseListOrMapLiteral_map_type() {
    var parseResult = parseStringWithErrors(r'''
var v = <String, int> {'1' : 1} <String, int> {'1' : 1};
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 3),
      error(diag.expectedExecutable, 44, 1),
      error(diag.expectedExecutable, 46, 1),
      error(diag.unexpectedToken, 55, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: BinaryExpression
              leftOperand: SetOrMapLiteral
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: String
                    NamedType
                      name: int
                  rightBracket: >
                leftBracket: {
                elements
                  MapLiteralEntry
                    key: SimpleStringLiteral
                      literal: '1'
                    separator: :
                    value: IntegerLiteral
                      literal: 1
                rightBracket: }
                isMap: false
              operator: <
              rightOperand: SimpleIdentifier
                token: String
          VariableDeclaration
            name: int
      semicolon: ; <synthetic>
''');
  }

  void test_parseLogicalAndExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = x && y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: &&
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseLogicalOrExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = x || y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: ||
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseMapLiteral_empty() {
    var parseResult = parseStringWithErrors(r'''
var v = <String, int>{};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: String
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: false
''');
  }

  void test_parseMapLiteral_multiple() {
    var parseResult = parseStringWithErrors(r'''
var v = {'a': b, 'x': y};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: SimpleIdentifier
        token: b
    MapLiteralEntry
      key: SimpleStringLiteral
        literal: 'x'
      separator: :
      value: SimpleIdentifier
        token: y
  rightBracket: }
  isMap: false
''');
  }

  void test_parseMapLiteral_multiple_trailing_comma() {
    var parseResult = parseStringWithErrors(r'''
var v = {'a': b, 'x': y};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: SimpleStringLiteral
        literal: 'a'
      separator: :
      value: SimpleIdentifier
        token: b
    MapLiteralEntry
      key: SimpleStringLiteral
        literal: 'x'
      separator: :
      value: SimpleIdentifier
        token: y
  rightBracket: }
  isMap: false
''');
  }

  void test_parseMapLiteral_single() {
    var parseResult = parseStringWithErrors(r'''
var v = {'x': y};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: SimpleStringLiteral
        literal: 'x'
      separator: :
      value: SimpleIdentifier
        token: y
  rightBracket: }
  isMap: false
''');
  }

  void test_parseMapLiteralEntry_complex() {
    var parseResult = parseStringWithErrors(r'''
var v = {2 + 2: y};
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.singleVariableDeclaration.initializer
                as SetOrMapLiteral)
            .elements
            .single;
    assertParsedNodeText(node, r'''
MapLiteralEntry
  key: BinaryExpression
    leftOperand: IntegerLiteral
      literal: 2
    operator: +
    rightOperand: IntegerLiteral
      literal: 2
  separator: :
  value: SimpleIdentifier
    token: y
''');
  }

  void test_parseMapLiteralEntry_int() {
    var parseResult = parseStringWithErrors(r'''
var v = {0: y};
''');
    parseResult.assertNoErrors();
    var node =
        (parseResult.findNode.singleVariableDeclaration.initializer
                as SetOrMapLiteral)
            .elements
            .single;
    assertParsedNodeText(node, r'''
MapLiteralEntry
  key: IntegerLiteral
    literal: 0
  separator: :
  value: SimpleIdentifier
    token: y
''');
  }

  void test_parseMapLiteralEntry_string() {
    var parseResult = parseStringWithErrors(r'''
var v = { x' :  };
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 11, 7),
      error(diag.expectedToken, 11, 7),
      error(diag.unterminatedStringLiteral, 17, 1),
      error(diag.expectedToken, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SetOrMapLiteral
              leftBracket: {
              elements
                SimpleIdentifier
                  token: x
                SimpleStringLiteral
                  literal: ' :  };' <synthetic>
              rightBracket: } <synthetic>
              isMap: false
      semicolon: ; <synthetic>
''');
  }

  void test_parseMultiplicativeExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x * y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: *
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseMultiplicativeExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super * y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: *
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseNewExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = new A();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parsePostfixExpression_decrement() {
    var parseResult = parseStringWithErrors(r'''
var v = i--;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: i
  operator: --
''');
  }

  void test_parsePostfixExpression_increment() {
    var parseResult = parseStringWithErrors(r'''
var v = i++;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PostfixExpression
  operand: SimpleIdentifier
    token: i
  operator: ++
''');
  }

  void test_parsePostfixExpression_none_indexExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = a[0];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IndexExpression
  target: SimpleIdentifier
    token: a
  leftBracket: [
  index: IntegerLiteral
    literal: 0
  rightBracket: ]
''');
  }

  void test_parsePostfixExpression_none_methodInvocation() {
    var parseResult = parseStringWithErrors(r'''
var v = a.m();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
  operator: .
  methodName: SimpleIdentifier
    token: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parsePostfixExpression_none_methodInvocation_question_dot() {
    var parseResult = parseStringWithErrors(r'''
var v = a?.m();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
  operator: ?.
  methodName: SimpleIdentifier
    token: m
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void
  test_parsePostfixExpression_none_methodInvocation_question_dot_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = a?.m<E>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
  operator: ?.
  methodName: SimpleIdentifier
    token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: E
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parsePostfixExpression_none_methodInvocation_typeArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = a.m<E>();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
MethodInvocation
  target: SimpleIdentifier
    token: a
  operator: .
  methodName: SimpleIdentifier
    token: m
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: E
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parsePostfixExpression_none_propertyAccess() {
    var parseResult = parseStringWithErrors(r'''
var v = a.b;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixedIdentifier
  prefix: SimpleIdentifier
    token: a
  period: .
  identifier: SimpleIdentifier
    token: b
''');
  }

  void test_parsePrefixedIdentifier_noPrefix() {
    var parseResult = parseStringWithErrors(r'''
var v = $lexeme;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $lexeme
''');
  }

  void test_parsePrefixedIdentifier_prefix() {
    var parseResult = parseStringWithErrors(r'''
var v = $lexeme;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $lexeme
''');
  }

  void test_parsePrimaryExpression_const() {
    var parseResult = parseStringWithErrors(r'''
var v = const A();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: const
  constructorName: ConstructorName
    type: NamedType
      name: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parsePrimaryExpression_double() {
    var parseResult = parseStringWithErrors(r'''
var v = $doubleLiteral;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $doubleLiteral
''');
  }

  void test_parsePrimaryExpression_false() {
    var parseResult = parseStringWithErrors(r'''
var v = false;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BooleanLiteral
  literal: false
''');
  }

  void test_parsePrimaryExpression_function_arguments() {
    var parseResult = parseStringWithErrors(r'''
var v = (int i) => i + 1;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
      name: i
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i
      operator: +
      rightOperand: IntegerLiteral
        literal: 1
''');
  }

  void test_parsePrimaryExpression_function_noArguments() {
    var parseResult = parseStringWithErrors(r'''
var v = () => 42;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IntegerLiteral
      literal: 42
''');
  }

  void test_parsePrimaryExpression_genericFunctionExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = <X, Y>(Map<X, Y> m, X x) => m[x];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: X
      TypeParameter
        name: Y
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: Map
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: X
            NamedType
              name: Y
          rightBracket: >
      name: m
    parameter: RegularFormalParameter
      type: NamedType
        name: X
      name: x
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: IndexExpression
      target: SimpleIdentifier
        token: m
      leftBracket: [
      index: SimpleIdentifier
        token: x
      rightBracket: ]
''');
  }

  void test_parsePrimaryExpression_hex() {
    var parseResult = parseStringWithErrors(r'''
var v = $hexLiteral;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $hexLiteral
''');
  }

  void test_parsePrimaryExpression_identifier() {
    var parseResult = parseStringWithErrors(r'''
var v = a;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: a
''');
  }

  void test_parsePrimaryExpression_int() {
    var parseResult = parseStringWithErrors(r'''
var v = $intLiteral;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $intLiteral
''');
  }

  void test_parsePrimaryExpression_listLiteral() {
    var parseResult = parseStringWithErrors(r'''
var v = [];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parsePrimaryExpression_listLiteral_index() {
    var parseResult = parseStringWithErrors(r'''
var v = [];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parsePrimaryExpression_listLiteral_typed() {
    var parseResult = parseStringWithErrors(r'''
var v = <A>[];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: A
    rightBracket: >
  leftBracket: [
  rightBracket: ]
''');
  }

  void test_parsePrimaryExpression_mapLiteral() {
    var parseResult = parseStringWithErrors(r'''
var v = {};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  rightBracket: }
  isMap: false
''');
  }

  void test_parsePrimaryExpression_mapLiteral_typed() {
    var parseResult = parseStringWithErrors(r'''
var v = <A, B>{};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: A
      NamedType
        name: B
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: false
''');
  }

  void test_parsePrimaryExpression_new() {
    var parseResult = parseStringWithErrors(r'''
var v = new A();
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
''');
  }

  void test_parsePrimaryExpression_null() {
    var parseResult = parseStringWithErrors(r'''
var v = null;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
NullLiteral
  literal: null
''');
  }

  void test_parsePrimaryExpression_parenthesized() {
    var parseResult = parseStringWithErrors(r'''
var v = (x);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ParenthesizedExpression
  leftParenthesis: (
  expression: SimpleIdentifier
    token: x
  rightParenthesis: )
''');
  }

  void test_parsePrimaryExpression_string() {
    var parseResult = parseStringWithErrors(r'''
var v = string;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: string
''');
  }

  void test_parsePrimaryExpression_string_multiline() {
    var parseResult = parseStringWithErrors(r'''
var v = string;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: string
''');
  }

  void test_parsePrimaryExpression_string_raw() {
    var parseResult = parseStringWithErrors(r'''
var v = r'string';
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleStringLiteral
  literal: r'string'
''');
  }

  void test_parsePrimaryExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super.x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PropertyAccess
  target: SuperExpression
    superKeyword: super
  operator: .
  propertyName: SimpleIdentifier
    token: x
''');
  }

  void test_parsePrimaryExpression_this() {
    var parseResult = parseStringWithErrors(r'''
var v = this;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ThisExpression
  thisKeyword: this
''');
  }

  void test_parsePrimaryExpression_true() {
    var parseResult = parseStringWithErrors(r'''
var v = true;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BooleanLiteral
  literal: true
''');
  }

  void test_parseRedirectingConstructorInvocation_named() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : this.a();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              RedirectingConstructorInvocation
                thisKeyword: this
                period: .
                constructorName: SimpleIdentifier
                  token: a
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseRedirectingConstructorInvocation_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : this();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              RedirectingConstructorInvocation
                thisKeyword: this
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseRelationalExpression_as_chained() {
    var parseResult = parseStringWithErrors(r'''
var v = x as Y as Z;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 15, 2)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: x
  asOperator: as
  type: NamedType
    name: Y
''');
  }

  void test_parseRelationalExpression_as_functionType_noReturnType() {
    var parseResult = parseStringWithErrors(r'''
var v = x as Function(int);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: x
  asOperator: as
  type: GenericFunctionType
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
      rightParenthesis: )
''');
  }

  void test_parseRelationalExpression_as_functionType_returnType() {
    var parseResult = parseStringWithErrors(r'''
var v = x as String Function(int);
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: x
  asOperator: as
  type: GenericFunctionType
    returnType: NamedType
      name: String
    functionKeyword: Function
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
      rightParenthesis: )
''');
  }

  void test_parseRelationalExpression_as_generic() {
    var parseResult = parseStringWithErrors(r'''
var v = x as C<D>;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: x
  asOperator: as
  type: NamedType
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: D
      rightBracket: >
''');
  }

  void test_parseRelationalExpression_as_simple() {
    var parseResult = parseStringWithErrors(r'''
var v = x as Y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: x
  asOperator: as
  type: NamedType
    name: Y
''');
  }

  void test_parseRelationalExpression_as_simple_function() {
    var parseResult = parseStringWithErrors(r'''
var v = x as Function;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
AsExpression
  expression: SimpleIdentifier
    token: x
  asOperator: as
  type: NamedType
    name: Function
''');
  }

  void test_parseRelationalExpression_is() {
    var parseResult = parseStringWithErrors(r'''
var v = x is y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: x
  isOperator: is
  type: NamedType
    name: y
''');
  }

  void test_parseRelationalExpression_is_chained() {
    var parseResult = parseStringWithErrors(r'''
var v = x is Y is! Z;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 15, 2)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: x
  isOperator: is
  type: NamedType
    name: Y
''');
  }

  void test_parseRelationalExpression_isNot() {
    var parseResult = parseStringWithErrors(r'''
var v = x is! y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
IsExpression
  expression: SimpleIdentifier
    token: x
  isOperator: is
  notOperator: !
  type: NamedType
    name: y
''');
  }

  void test_parseRelationalExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x < y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: <
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseRelationalExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super < y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: <
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseRethrowExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = rethrow;
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 8, 7),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: rethrow
''');
  }

  void test_parseShiftExpression_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = x << y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SimpleIdentifier
    token: x
  operator: <<
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseShiftExpression_super() {
    var parseResult = parseStringWithErrors(r'''
var v = super << y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
BinaryExpression
  leftOperand: SuperExpression
    superKeyword: super
  operator: <<
  rightOperand: SimpleIdentifier
    token: y
''');
  }

  void test_parseSimpleIdentifier1_normalIdentifier() {
    // TODO(brianwilkerson): Implement tests for this method.
  }

  void test_parseSimpleIdentifier_builtInIdentifier() {
    var parseResult = parseStringWithErrors(r'''
var v = $lexeme;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $lexeme
''');
  }

  void test_parseSimpleIdentifier_normalIdentifier() {
    var parseResult = parseStringWithErrors(r'''
var v = $lexeme;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $lexeme
''');
  }

  void test_parseStringLiteral_adjacent() {
    var parseResult = parseStringWithErrors(r'''
var v = a' 'b;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 9, 3),
      error(diag.missingConstFinalVarOrType, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: b
      semicolon: ;
''');
  }

  void test_parseStringLiteral_endsWithInterpolation() {
    var parseResult = parseStringWithErrors(r'''
var v = x$y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: x$y
''');
  }

  void test_parseStringLiteral_interpolated() {
    var parseResult = parseStringWithErrors(r'''
var v = a ${b} c $this d;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.missingFunctionParameters, 10, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 17, 5),
      error(diag.missingConstFinalVarOrType, 23, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: a
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: $
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: b
                semicolon: ; <synthetic>
            rightBracket: }
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: c
        variables
          VariableDeclaration
            name: $this
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: d
      semicolon: ;
''');
  }

  void test_parseStringLiteral_interpolated_void() {
    var parseResult = parseStringWithErrors(r'''
var v = <html>$void</html>;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 14, 5),
      error(diag.missingFunctionParameters, 14, 5),
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 21, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: ListLiteral
              typeArguments: TypeArgumentList
                leftBracket: <
                arguments
                  NamedType
                    name: html
                rightBracket: >
              leftBracket: [ <synthetic>
              rightBracket: ] <synthetic>
      semicolon: ; <synthetic>
    FunctionDeclaration
      name: $void
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: <empty> <synthetic>
            TypeParameter
              name: html
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: EmptyFunctionBody
          semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_encodedSpace() {
    var parseResult = parseStringWithErrors(r'''
var v = \x20
a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: x20
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_endsWithInterpolation() {
    var parseResult = parseStringWithErrors(r'''
var v = x$y;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: x$y
''');
  }

  void test_parseStringLiteral_multiline_escapedBackslash() {
    var parseResult = parseStringWithErrors(r'''
var v = \\
a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 9, 1),
      error(diag.missingConstFinalVarOrType, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_escapedBackslash_raw() {
    var parseResult = parseStringWithErrors(r"""
var v = r'''\\
a''';
""");
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r"""
SimpleStringLiteral
  literal: r'''\\
a'''
""");
  }

  void test_parseStringLiteral_multiline_escapedEolMarker() {
    var parseResult = parseStringWithErrors(r'''
var v = \
a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 8, 1),
      error(diag.missingConstFinalVarOrType, 10, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_escapedEolMarker_raw() {
    var parseResult = parseStringWithErrors(r"""
var v = r'''\
a''';
""");
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r"""
SimpleStringLiteral
  literal: r'''\
a'''
""");
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker() {
    var parseResult = parseStringWithErrors(r'''
var v = \ \
a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 10, 1),
      error(diag.missingConstFinalVarOrType, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_escapedSpaceAndEolMarker_raw() {
    var parseResult = parseStringWithErrors(r"""
var v = r'''\ \
a''';
""");
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r"""
SimpleStringLiteral
  literal: r'''\ \
a'''
""");
  }

  void test_parseStringLiteral_multiline_escapedTab() {
    var parseResult = parseStringWithErrors(r'''
var v = \t
a;
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 8, 1),
      error(diag.expectedToken, 8, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: <empty> <synthetic>
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: t
        variables
          VariableDeclaration
            name: a
      semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_escapedTab_raw() {
    var parseResult = parseStringWithErrors(r"""
var v = r'''\t
a''';
""");
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r"""
SimpleStringLiteral
  literal: r'''\t
a'''
""");
  }

  void test_parseStringLiteral_multiline_quoteAfterInterpolation() {
    var parseResult = parseStringWithErrors(r'''
var v = $x'y;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 2),
      error(diag.expectedExecutable, 10, 3),
      error(diag.unterminatedStringLiteral, 12, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $x
''');
  }

  void test_parseStringLiteral_multiline_startsWithInterpolation() {
    var parseResult = parseStringWithErrors(r'''
var v = ${x}y;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 9, 1),
      error(diag.missingConstFinalVarOrType, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: $
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: y
      semicolon: ;
''');
  }

  void test_parseStringLiteral_multiline_twoSpaces() {
    var parseResult = parseStringWithErrors(r'''
var v = a;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: a
''');
  }

  void test_parseStringLiteral_multiline_twoSpaces_raw() {
    var parseResult = parseStringWithErrors(r"""
var v = r'''  
a''';
""");
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r"""
SimpleStringLiteral
  literal: r'''  
a'''
""");
  }

  void test_parseStringLiteral_multiline_untrimmed() {
    var parseResult = parseStringWithErrors(r'''
var v =  a
b;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 1),
      error(diag.missingConstFinalVarOrType, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: a
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: b
      semicolon: ;
''');
  }

  void test_parseStringLiteral_quoteAfterInterpolation() {
    var parseResult = parseStringWithErrors(r'''
var v = $x";
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 2),
      error(diag.expectedExecutable, 10, 2),
      error(diag.unterminatedStringLiteral, 11, 1),
    ]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: $x
''');
  }

  void test_parseStringLiteral_single() {
    var parseResult = parseStringWithErrors(r'''
var v = a;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SimpleIdentifier
  token: a
''');
  }

  void test_parseStringLiteral_startsWithInterpolation() {
    var parseResult = parseStringWithErrors(r'''
var v = ${x}y;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 8, 1),
      error(diag.expectedExecutable, 9, 1),
      error(diag.missingConstFinalVarOrType, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: v
            equals: =
            initializer: SimpleIdentifier
              token: $
      semicolon: ; <synthetic>
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        variables
          VariableDeclaration
            name: y
      semicolon: ;
''');
  }

  void test_parseSuperConstructorInvocation_named() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : super.a();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                period: .
                constructorName: SimpleIdentifier
                  token: a
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseSuperConstructorInvocation_unnamed() {
    var parseResult = parseStringWithErrors(r'''
class C {
  C() : super();
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        members
          ConstructorDeclaration
            typeName: SimpleIdentifier
              token: C
            parameters: FormalParameterList
              leftParenthesis: (
              rightParenthesis: )
            separator: :
            initializers
              SuperConstructorInvocation
                superKeyword: super
                argumentList: ArgumentList
                  leftParenthesis: (
                  rightParenthesis: )
            body: EmptyFunctionBody
              semicolon: ;
        rightBracket: }
''');
  }

  void test_parseSymbolLiteral_builtInIdentifier() {
    var parseResult = parseStringWithErrors(r'''
var v = #dynamic.static.abstract;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SymbolLiteral
  poundSign: #
  components
    dynamic
    static
    abstract
''');
  }

  void test_parseSymbolLiteral_multiple() {
    var parseResult = parseStringWithErrors(r'''
var v = #a.b.c;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SymbolLiteral
  poundSign: #
  components
    a
    b
    c
''');
  }

  void test_parseSymbolLiteral_operator() {
    var parseResult = parseStringWithErrors(r'''
var v = #==;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SymbolLiteral
  poundSign: #
  components
    ==
''');
  }

  void test_parseSymbolLiteral_single() {
    var parseResult = parseStringWithErrors(r'''
var v = #a;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SymbolLiteral
  poundSign: #
  components
    a
''');
  }

  void test_parseSymbolLiteral_void() {
    var parseResult = parseStringWithErrors(r'''
var v = #void;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SymbolLiteral
  poundSign: #
  components
    void
''');
  }

  void test_parseThrowExpression() {
    var parseResult = parseStringWithErrors(r'''
var v = throw x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ThrowExpression
  throwKeyword: throw
  expression: SimpleIdentifier
    token: x
''');
  }

  void test_parseThrowExpressionWithoutCascade() {
    var parseResult = parseStringWithErrors(r'''
var v = throw x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
ThrowExpression
  throwKeyword: throw
  expression: SimpleIdentifier
    token: x
''');
  }

  void test_parseUnaryExpression_decrement_identifier_index() {
    var parseResult = parseStringWithErrors(r'''
var v = --a[0];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: --
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
''');
  }

  void test_parseUnaryExpression_decrement_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = --x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: --
  operand: SimpleIdentifier
    token: x
''');
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super() {
    var parseResult = parseStringWithErrors(r'''
var v = --super;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
''');
  }

  void test_parseUnaryExpression_decrement_super_propertyAccess() {
    var parseResult = parseStringWithErrors(r'''
var v = --super.x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: --
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
    operator: .
    propertyName: SimpleIdentifier
      token: x
''');
  }

  @failingTest
  void test_parseUnaryExpression_decrement_super_withComment() {
    var parseResult = parseStringWithErrors(r'''
var v = /* 0 */ --super;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
''');
  }

  void test_parseUnaryExpression_increment_identifier_index() {
    var parseResult = parseStringWithErrors(r'''
var v = ++a[0];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
''');
  }

  void test_parseUnaryExpression_increment_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = ++x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: SimpleIdentifier
    token: x
''');
  }

  void test_parseUnaryExpression_increment_super_index() {
    var parseResult = parseStringWithErrors(r'''
var v = ++super[0];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: IndexExpression
    target: SuperExpression
      superKeyword: super
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
''');
  }

  void test_parseUnaryExpression_increment_super_propertyAccess() {
    var parseResult = parseStringWithErrors(r'''
var v = ++super.x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ++
  operand: PropertyAccess
    target: SuperExpression
      superKeyword: super
    operator: .
    propertyName: SimpleIdentifier
      token: x
''');
  }

  void test_parseUnaryExpression_minus_identifier_index() {
    var parseResult = parseStringWithErrors(r'''
var v = -a[0];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
''');
  }

  void test_parseUnaryExpression_minus_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = -x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SimpleIdentifier
    token: x
''');
  }

  void test_parseUnaryExpression_minus_super() {
    var parseResult = parseStringWithErrors(r'''
var v = -super;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: -
  operand: SuperExpression
    superKeyword: super
''');
  }

  void test_parseUnaryExpression_not_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = !x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SimpleIdentifier
    token: x
''');
  }

  void test_parseUnaryExpression_not_super() {
    var parseResult = parseStringWithErrors(r'''
var v = !super;
''');
    parseResult.assertErrors([error(diag.missingAssignableSelector, 9, 5)]);
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: !
  operand: SuperExpression
    superKeyword: super
''');
  }

  void test_parseUnaryExpression_tilda_normal() {
    var parseResult = parseStringWithErrors(r'''
var v = ~x;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: SimpleIdentifier
    token: x
''');
  }

  void test_parseUnaryExpression_tilda_super() {
    var parseResult = parseStringWithErrors(r'''
var v = ~super;
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: SuperExpression
    superKeyword: super
''');
  }

  void test_parseUnaryExpression_tilde_identifier_index() {
    var parseResult = parseStringWithErrors(r'''
var v = ~a[0];
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
PrefixExpression
  operator: ~
  operand: IndexExpression
    target: SimpleIdentifier
      token: a
    leftBracket: [
    index: IntegerLiteral
      literal: 0
    rightBracket: ]
''');
  }

  void test_setLiteral() {
    var parseResult = parseStringWithErrors(r'''
var v = {3};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 3
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_const() {
    var parseResult = parseStringWithErrors(r'''
var v = const {3, 6};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  constKeyword: const
  leftBracket: {
  elements
    IntegerLiteral
      literal: 3
    IntegerLiteral
      literal: 6
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_const_typed() {
    var parseResult = parseStringWithErrors(r'''
var v = const <int>{3};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  constKeyword: const
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    IntegerLiteral
      literal: 3
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_nested_typeArgument() {
    var parseResult = parseStringWithErrors(r'''
var v = <Set<int>>{
  {3},
};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: Set
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
          rightBracket: >
    rightBracket: >
  leftBracket: {
  elements
    SetOrMapLiteral
      leftBracket: {
      elements
        IntegerLiteral
          literal: 3
      rightBracket: }
      isMap: false
  rightBracket: }
  isMap: false
''');
  }

  void test_setLiteral_typed() {
    var parseResult = parseStringWithErrors(r'''
var v = <int>{3};
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleVariableDeclaration.initializer!;
    assertParsedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
    rightBracket: >
  leftBracket: {
  elements
    IntegerLiteral
      literal: 3
  rightBracket: }
  isMap: false
''');
  }
}
