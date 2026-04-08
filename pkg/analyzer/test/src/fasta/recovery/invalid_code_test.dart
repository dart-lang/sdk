// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidCodeTest);
    defineReflectiveTests(MisplacedCodeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidCodeTest extends ParserDiagnosticsTest {
  void test_const_mistyped() {
    var parseResult = parseStringWithErrors(r'''
List<String> fruits = cont <String>['apples', 'bananas', 'pears'];
''');
    parseResult.assertErrors([
      error(diag.equalityCannotBeEqualityOperand, 34, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: List
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: String
            rightBracket: >
        variables
          VariableDeclaration
            name: fruits
            equals: =
            initializer: BinaryExpression
              leftOperand: BinaryExpression
                leftOperand: SimpleIdentifier
                  token: cont
                operator: <
                rightOperand: SimpleIdentifier
                  token: String
              operator: >
              rightOperand: ListLiteral
                leftBracket: [
                elements
                  SimpleStringLiteral
                    literal: 'apples'
                  SimpleStringLiteral
                    literal: 'bananas'
                  SimpleStringLiteral
                    literal: 'pears'
                rightBracket: ]
      semicolon: ;
''');
  }

  void test_default_asVariableName() {
    var parseResult = parseStringWithErrors(r'''
const default = const Object();
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 6, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: const
        variables
          VariableDeclaration
            name: default
            equals: =
            initializer: InstanceCreationExpression
              keyword: const
              constructorName: ConstructorName
                type: NamedType
                  name: Object
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
      semicolon: ;
''');
  }

  void test_expressionInPlaceOfTypeName() {
    var parseResult = parseStringWithErrors(r'''
f() {
  return <g('')>[0, 1, 2];
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ReturnStatement
                returnKeyword: return
                expression: ListLiteral
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: g
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
                semicolon: ;
            rightBracket: }
''');
  }

  void test_expressionInPlaceOfTypeName2() {
    var parseResult = parseStringWithErrors(r'''
f() {
  return <test('', (){})>[0, 1, 2];
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ReturnStatement
                returnKeyword: return
                expression: ListLiteral
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
                semicolon: ;
            rightBracket: }
''');
  }

  void test_functionInPlaceOfTypeName() {
    var parseResult = parseStringWithErrors(r'''
f() {
  return <test('', (){});>[0, 1, 2];
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ReturnStatement
                returnKeyword: return
                expression: ListLiteral
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
                semicolon: ;
            rightBracket: }
''');
  }

  void test_with_asArgumentName() {
    var parseResult = parseStringWithErrors(r'''
f() {}
g() {
  f(with: 3);
}
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 17, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    FunctionDeclaration
      name: g
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: MethodInvocation
                  methodName: SimpleIdentifier
                    token: f
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      NamedExpression
                        name: Label
                          label: SimpleIdentifier
                            token: with
                          colon: :
                        expression: IntegerLiteral
                          literal: 3
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_with_asParameterName() {
    var parseResult = parseStringWithErrors(r'''
f({int with: 0}) {}
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 7, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          leftDelimiter: {
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: with
            defaultClause: FormalParameterDefaultClause
              separator: :
              value: IntegerLiteral
                literal: 0
          rightDelimiter: }
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
''');
  }
}

@reflectiveTest
class MisplacedCodeTest extends ParserDiagnosticsTest {
  void test_const_mistyped() {
    var parseResult = parseStringWithErrors(r'''
var allValues = [];
allValues.forEach((enum) {});
''');
    parseResult.assertErrors([
      error(diag.missingFunctionParameters, 20, 9),
      error(diag.missingFunctionBody, 29, 1),
      error(diag.expectedExecutable, 29, 1),
      error(diag.expectedIdentifierButGotKeyword, 39, 4),
      error(diag.missingIdentifier, 38, 1),
      error(diag.expectedToken, 45, 1),
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
            name: allValues
            equals: =
            initializer: ListLiteral
              leftBracket: [
              rightBracket: ]
      semicolon: ;
    FunctionDeclaration
      name: allValues
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: forEach
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            name: <empty> <synthetic>
            functionTypedSuffix: FunctionTypedFormalParameterSuffix
              formalParameters: FormalParameterList
                leftParenthesis: (
                parameter: RegularFormalParameter
                  name: enum
                rightParenthesis: )
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
''');
  }
}
