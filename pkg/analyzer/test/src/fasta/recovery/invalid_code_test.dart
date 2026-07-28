// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<String> fruits = cont <String>['apples', 'bananas', 'pears'];
//                                ^
// [diag.equalityCannotBeEqualityOperand] A comparison expression can't be an operand of another comparison expression.
''');
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
            initializer2: BinaryExpression
              leftOperand2: BinaryExpression
                leftOperand2: SimpleIdentifier
                  token: cont
                operator: <
                rightOperand2: SimpleIdentifier
                  token: String
              operator: >
              rightOperand2: ListLiteral
                leftBracket: [
                elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
const default = const Object();
//    ^^^^^^^
// [diag.expectedIdentifierButGotKeyword] 'default' can't be used as an identifier because it's a keyword.
''');
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
            initializer2: ConstructorInvocation
              keyword: const
              constructorReference: ConstructorReference2
                typeReference: ConstructorTypeReference
                  name: Object
              argumentList: ArgumentList
                leftParenthesis: (
                rightParenthesis: )
            initializer(v1): InstanceCreationExpression
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {
  return <g('')>[0, 1, 2];
//        ^
// [diag.expectedToken] Expected to find '>'.
}
''');
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
                expression2: ListLiteral
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: g
                    rightBracket: >
                  leftBracket: [
                  elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {
  return <test('', (){})>[0, 1, 2];
//        ^^^^
// [diag.expectedToken] Expected to find '>'.
}
''');
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
                expression2: ListLiteral
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: test
                    rightBracket: >
                  leftBracket: [
                  elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {
  return <test('', (){});>[0, 1, 2];
//        ^^^^
// [diag.expectedToken] Expected to find '>'.
}
''');
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
                expression2: ListLiteral
                  typeArguments: TypeArgumentList
                    leftBracket: <
                    arguments
                      NamedType
                        name: test
                    rightBracket: >
                  leftBracket: [
                  elements2
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() {}
g() {
  f(with: 3);
//  ^^^^
// [diag.expectedIdentifierButGotKeyword] 'with' can't be used as an identifier because it's a keyword.
}
''');
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
                expression2: MethodInvocation
                  methodName: SimpleIdentifier
                    token: f
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments2
                      NamedArgument
                        name: with
                        colon: :
                        argumentExpression2: IntegerLiteral
                          literal: 3
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_with_asParameterName() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f({int with: 0}) {}
//     ^^^^
// [diag.expectedIdentifierButGotKeyword] 'with' can't be used as an identifier because it's a keyword.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          delimitedFormalParameters: DelimitedFormalParameters
            leftDelimiter: {
            formalParameters
              RegularFormalParameter
                type: NamedType
                  name: int
                name: with
                defaultClause: FormalParameterDefaultClause
                  separator: :
                  value2: IntegerLiteral
                    literal: 0
            rightDelimiter: }
          rightParenthesis: )
        parameters(v1): FormalParameterList
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
var allValues = [];
allValues.forEach((enum) {});
// [diag.missingFunctionParameters][column 1][length 9] Functions must have an explicit list of parameters.
//       ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.expectedExecutable] Expected a method, getter, setter or operator declaration.
//                ^
// [diag.missingIdentifier] Expected an identifier.
//                 ^^^^
// [diag.expectedIdentifierButGotKeyword] 'enum' can't be used as an identifier because it's a keyword.
//                       ^
// [diag.expectedToken] Expected to find ')'.
''');
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
            initializer2: ListLiteral
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
          requiredPositionalFormalParameters
            RegularFormalParameter
              name: <empty> <synthetic>
              functionTypedSuffix: FunctionTypedFormalParameterSuffix
                formalParameters: FormalParameterList
                  leftParenthesis: (
                  requiredPositionalFormalParameters
                    RegularFormalParameter
                      name: enum
                  rightParenthesis: )
                formalParameters(v1): FormalParameterList
                  leftParenthesis: (
                  parameter: RegularFormalParameter
                    name: enum
                  rightParenthesis: )
          rightParenthesis: )
        parameters(v1): FormalParameterList
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
