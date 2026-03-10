// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AngleBracketsTest);
    defineReflectiveTests(BracesTest);
    defineReflectiveTests(BracketsTest);
    defineReflectiveTests(ParenthesesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

/// Test how well the parser recovers when angle brackets (`<` and `>`) are
/// mismatched.
@reflectiveTest
class AngleBracketsTest extends ParserDiagnosticsTest {
  void test_typeArguments_inner_last() {
    var parseResult = parseStringWithErrors(r'''
List<List<int>
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 0),
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 13, 1),
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
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_inner_last2() {
    var parseResult = parseStringWithErrors(r'''
List<List<int> f;
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
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
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeArguments_inner_notLast() {
    var parseResult = parseStringWithErrors(r'''
Map<List<int, List<String>>
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 28, 0),
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 26, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: Map
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                    NamedType
                      name: List
                      typeArguments: TypeArgumentList
                        leftBracket: <
                        arguments
                          NamedType
                            name: String
                        rightBracket: >
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_inner_notLast2() {
    var parseResult = parseStringWithErrors(r'''
Map<List<int, List<String>> f;
''');
    parseResult.assertErrors([error(diag.expectedToken, 26, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        type: NamedType
          name: Map
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                    NamedType
                      name: List
                      typeArguments: TypeArgumentList
                        leftBracket: <
                        arguments
                          NamedType
                            name: String
                        rightBracket: >
                  rightBracket: >
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeArguments_missing_comma() {
    var parseResult = parseStringWithErrors(r'''
List<int double> f;
''');
    parseResult.assertErrors([error(diag.expectedToken, 9, 6)]);
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
                name: int
              NamedType
                name: double
            rightBracket: >
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeArguments_outer_last() {
    var parseResult = parseStringWithErrors(r'''
List<int
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 0),
      error(diag.expectedToken, 5, 3),
      error(diag.expectedToken, 5, 3),
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
                name: int
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_outer_last2() {
    var parseResult = parseStringWithErrors(r'''
List<int f;
''');
    parseResult.assertErrors([error(diag.expectedToken, 5, 3)]);
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
                name: int
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeParameters_extraGt() {
    var parseResult = parseStringWithErrors(r'''
f<T>>() => null;
''');
    parseResult.assertErrors([
      error(diag.missingFunctionParameters, 0, 1),
      error(diag.missingFunctionBody, 4, 1),
      error(diag.topLevelOperator, 4, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    FunctionDeclaration
      name: #synthetic_function_4 <synthetic>
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_funct() {
    var parseResult = parseStringWithErrors(r'''
f<T extends Function()() => null;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingFunctionParameters, 0, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: GenericFunctionType
                functionKeyword: Function
                parameters: FormalParameterList
                  leftParenthesis: (
                  rightParenthesis: )
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_funct2() {
    var parseResult = parseStringWithErrors(r'''
f<T extends Function<X>()() => null;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingFunctionParameters, 0, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: GenericFunctionType
                functionKeyword: Function
                typeParameters: TypeParameterList
                  leftBracket: <
                  typeParameters
                    TypeParameter
                      name: X
                  rightBracket: >
                parameters: FormalParameterList
                  leftParenthesis: (
                  rightParenthesis: )
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_gtEq() {
    var parseResult = parseStringWithErrors(r'''
f<T>=() => null;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 4, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
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
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_gtGtEq() {
    var parseResult = parseStringWithErrors(r'''
f<T extends List<int>>=() => null;
''');
    parseResult.assertErrors([error(diag.unexpectedToken, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
          rightBracket: >
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_last() {
    var parseResult = parseStringWithErrors(r'''
f<T() => null;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 2, 1),
      error(diag.missingFunctionParameters, 0, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }

  void test_typeParameters_outer_last() {
    var parseResult = parseStringWithErrors(r'''
f<T extends List<int>() => null;
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingFunctionParameters, 0, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        typeParameters: TypeParameterList
          leftBracket: <
          typeParameters
            TypeParameter
              name: T
              extendsKeyword: extends
              bound: NamedType
                name: List
                typeArguments: TypeArgumentList
                  leftBracket: <
                  arguments
                    NamedType
                      name: int
                  rightBracket: >
          rightBracket: > <synthetic>
        parameters: FormalParameterList
          leftParenthesis: ( <synthetic>
          rightParenthesis: ) <synthetic>
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: NullLiteral
            literal: null
          semicolon: ;
''');
  }
}

/// Test how well the parser recovers when curly braces are mismatched.
@reflectiveTest
class BracesTest extends ParserDiagnosticsTest {
  void test_statement_if_last() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  if (x != null) {
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 26, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: x
                  operator: !=
                  rightOperand: NullLiteral
                    literal: null
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_statement_if_while() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  if (x != null) {
  while (x == null) {}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 49, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BinaryExpression
                  leftOperand: SimpleIdentifier
                    token: x
                  operator: !=
                  rightOperand: NullLiteral
                    literal: null
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  statements
                    WhileStatement
                      whileKeyword: while
                      leftParenthesis: (
                      condition: BinaryExpression
                        leftOperand: SimpleIdentifier
                          token: x
                        operator: ==
                        rightOperand: NullLiteral
                          literal: null
                      rightParenthesis: )
                      body: Block
                        leftBracket: {
                        rightBracket: }
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_unit_functionBody_class() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
class C {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.expectedIdentifierButGotKeyword, 7, 5),
      error(diag.expectedToken, 7, 5),
      error(diag.missingStatement, 7, 5),
      error(diag.expectedToken, 13, 1),
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
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: class
                semicolon: ; <synthetic>
              ExpressionStatement
                expression: SimpleIdentifier
                  token: C
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_function() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
g(y) => y;
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  name: g
                  functionExpression: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      parameter: SimpleFormalParameter
                        name: y
                      rightParenthesis: )
                    body: ExpressionFunctionBody
                      functionDefinition: =>
                      expression: SimpleIdentifier
                        token: y
                      semicolon: ;
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_last() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
''');
    parseResult.assertErrors([error(diag.expectedToken, 7, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_variable() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
int y = 0;
''');
    parseResult.assertErrors([error(diag.expectedToken, 18, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: y
                      equals: =
                      initializer: IntegerLiteral
                        literal: 0
                semicolon: ;
            rightBracket: } <synthetic>
''');
  }
}

/// Test how well the parser recovers when square brackets are mismatched.
@reflectiveTest
class BracketsTest extends ParserDiagnosticsTest {
  void test_indexOperator() {
    var parseResult = parseStringWithErrors(r'''
f(x) => l[x
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 10, 1),
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
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IndexExpression
            target: SimpleIdentifier
              token: l
            leftBracket: [
            index: SimpleIdentifier
              token: x
            rightBracket: ] <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_indexOperator_nullAware() {
    var parseResult = parseStringWithErrors(r'''
f(x) => l?[x
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 11, 1),
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
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IndexExpression
            target: SimpleIdentifier
              token: l
            question: ?
            leftBracket: [
            index: SimpleIdentifier
              token: x
            rightBracket: ] <synthetic>
          semicolon: ; <synthetic>
''');
  }

  void test_listLiteral_inner_last() {
    var parseResult = parseStringWithErrors(r'''
var x = [[0], [1];
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 0
                  rightBracket: ]
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 1
                  rightBracket: ]
              rightBracket: ] <synthetic>
      semicolon: ;
''');
  }

  void test_listLiteral_inner_notLast() {
    var parseResult = parseStringWithErrors(r'''
var x = [[0], [1, [2]];
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 0
                  rightBracket: ]
                ListLiteral
                  leftBracket: [
                  elements
                    IntegerLiteral
                      literal: 1
                    ListLiteral
                      leftBracket: [
                      elements
                        IntegerLiteral
                          literal: 2
                      rightBracket: ]
                  rightBracket: ]
              rightBracket: ] <synthetic>
      semicolon: ;
''');
  }

  void test_listLiteral_missing_comma() {
    var parseResult = parseStringWithErrors(r'''
var x = [0 1];
''');
    parseResult.assertErrors([error(diag.expectedToken, 11, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    TopLevelVariableDeclaration
      variables: VariableDeclarationList
        keyword: var
        variables
          VariableDeclaration
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                IntegerLiteral
                  literal: 0
                IntegerLiteral
                  literal: 1
              rightBracket: ]
      semicolon: ;
''');
  }

  void test_listLiteral_outer_last() {
    var parseResult = parseStringWithErrors(r'''
var x = [0, 1
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.expectedToken, 12, 1),
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
            name: x
            equals: =
            initializer: ListLiteral
              leftBracket: [
              elements
                IntegerLiteral
                  literal: 0
                IntegerLiteral
                  literal: 1
              rightBracket: ] <synthetic>
      semicolon: ; <synthetic>
''');
  }
}

/// Test how well the parser recovers when parentheses are mismatched.
@reflectiveTest
class ParenthesesTest extends ParserDiagnosticsTest {
  void test_if_last() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  if (x
}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 13, 1),
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
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_while() {
    var parseResult = parseStringWithErrors(r'''
f(x) {
  if (x
  while(x != null) {}
}
''');
    parseResult.assertErrors([error(diag.expectedToken, 37, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: ) <synthetic>
                thenStatement: WhileStatement
                  whileKeyword: while
                  leftParenthesis: (
                  condition: BinaryExpression
                    leftOperand: SimpleIdentifier
                      token: x
                    operator: !=
                    rightOperand: NullLiteral
                      literal: null
                  rightParenthesis: )
                  body: Block
                    leftBracket: {
                    rightBracket: }
            rightBracket: }
''');
  }

  void test_parameterList_class() {
    var parseResult = parseStringWithErrors(r'''
f(x
class C {}
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.missingFunctionBody, 4, 5),
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
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  void test_parameterList_eof() {
    var parseResult = parseStringWithErrors(r'''
f(x
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 4, 1),
      error(diag.missingFunctionBody, 4, 0),
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
          parameter: SimpleFormalParameter
            name: x
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
''');
  }
}
