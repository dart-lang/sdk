// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<List<int>
//           ^
// [diag.expectedToken] Expected to find '>'.
// [diag.expectedToken] Expected to find ';'.
//            ^
// [diag.missingIdentifier][column 15][length 0] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<List<int> f;
//           ^
// [diag.expectedToken] Expected to find '>'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<List<int, List<String>>
//                        ^
// [diag.expectedToken] Expected to find '>'.
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.missingIdentifier][column 28][length 0] Expected an identifier.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
Map<List<int, List<String>> f;
//                        ^
// [diag.expectedToken] Expected to find '>'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int double> f;
//       ^^^^^^
// [diag.expectedToken] Expected to find ','.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int
//   ^^^
// [diag.expectedToken] Expected to find '>'.
// [diag.expectedToken] Expected to find ';'.
//      ^
// [diag.missingIdentifier][column 9][length 0] Expected an identifier.
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
                name: int
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: <empty> <synthetic>
      semicolon: ; <synthetic>
''');
  }

  void test_typeArguments_outer_last2() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
List<int f;
//   ^^^
// [diag.expectedToken] Expected to find '>'.
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
                name: int
            rightBracket: > <synthetic>
        variables
          VariableDeclaration
            name: f
      semicolon: ;
''');
  }

  void test_typeParameters_extraGt() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T>>() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//  ^
// [diag.missingFunctionBody] A function body must be provided.
// [diag.topLevelOperator] Operators must be declared within a class.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends Function()() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//                   ^
// [diag.expectedToken] Expected to find '>'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends Function<X>()() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//                      ^
// [diag.expectedToken] Expected to find '>'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T>=() => null;
//  ^
// [diag.unexpectedToken] Unexpected text '='.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends List<int>>=() => null;
//                    ^
// [diag.unexpectedToken] Unexpected text '='.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//^
// [diag.expectedToken] Expected to find '>'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f<T extends List<int>() => null;
// [diag.missingFunctionParameters][column 1][length 1] Functions must have an explicit list of parameters.
//                  ^
// [diag.expectedToken] Expected to find '>'.
''');
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x != null) {
}
// [diag.expectedToken][column 1][length 1] Expected to find '}'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x != null) {
  while (x == null) {}
}
// [diag.expectedToken][column 1][length 1] Expected to find '}'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
class C {}
// [diag.expectedIdentifierButGotKeyword][column 1][length 5] 'class' can't be used as an identifier because it's a keyword.
// [diag.expectedToken][column 1][length 5] Expected to find ';'.
// [diag.missingStatement][column 1][length 5] Expected a statement.
//    ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 11][length 1] Expected to find '}'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
g(y) => y;
// [diag.expectedToken][column 11][length 1] Expected to find '}'.
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
          parameter: RegularFormalParameter
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
                      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
// [diag.expectedToken][column 7][length 1] Expected to find '}'.
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
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: } <synthetic>
''');
  }

  void test_unit_functionBody_variable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
int y = 0;
// [diag.expectedToken][column 11][length 1] Expected to find '}'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) => l[x
//        ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 12][length 1] Expected to find ']'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) => l?[x
//         ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 13][length 1] Expected to find ']'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [[0], [1];
//               ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [[0], [1, [2]];
//                    ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [0 1];
//         ^
// [diag.expectedToken] Expected to find ','.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
var x = [0, 1
//          ^
// [diag.expectedToken] Expected to find ';'.
// [diag.expectedToken][column 14][length 1] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x
//    ^
// [diag.expectedToken] Expected to find ';'.
}
// [diag.missingIdentifier][column 1][length 1] Expected an identifier.
// [diag.expectedToken][column 1][length 1] Expected to find ')'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x) {
  if (x
  while(x != null) {}
//^
// [diag.expectedToken] Expected to find ')'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x
class C {}
// [diag.missingFunctionBody][column 1][length 5] A function body must be provided.
// [diag.expectedToken][column 1][length 1] Expected to find ')'.
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f(x
// ^
// [diag.missingFunctionBody][column 4][length 0] A function body must be provided.
// [diag.expectedToken][column 4][length 1] Expected to find ')'.
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
          parameter: RegularFormalParameter
            name: x
          rightParenthesis: ) <synthetic>
        body: BlockFunctionBody
          block: Block
            leftBracket: { <synthetic>
            rightBracket: } <synthetic>
''');
  }
}
