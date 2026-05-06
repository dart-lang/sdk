// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IndexStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IndexStatementTest extends ParserDiagnosticsTest {
  void test_index_assignment_missing_index_no_space_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[] = 0; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 14, 1)]);
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
              ExpressionStatement
                expression: AssignmentExpression
                  leftHandSide: IndexExpression
                    target: SimpleIdentifier
                      token: intList
                    leftBracket: [
                    index: SimpleIdentifier
                      token: <empty> <synthetic>
                    rightBracket: ]
                  operator: =
                  rightHandSide: IntegerLiteral
                    literal: 0
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_assignment_missing_index_with_space_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ ] = 0; }
''');
    parseResult.assertErrors([error(diag.missingIdentifier, 15, 1)]);
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
              ExpressionStatement
                expression: AssignmentExpression
                  leftHandSide: IndexExpression
                    target: SimpleIdentifier
                      token: intList
                    leftBracket: [
                    index: SimpleIdentifier
                      token: <empty> <synthetic>
                    rightBracket: ]
                  operator: =
                  rightHandSide: IntegerLiteral
                    literal: 0
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_assignment_trailing_comma_and_identifier_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x,y] = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 1)]);
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
              ExpressionStatement
                expression: AssignmentExpression
                  leftHandSide: IndexExpression
                    target: SimpleIdentifier
                      token: intList
                    leftBracket: [
                    index: SimpleIdentifier
                      token: x
                    rightBracket: ]
                  operator: =
                  rightHandSide: IntegerLiteral
                    literal: 0
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_assignment_trailing_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x,] = 0; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 1)]);
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
              ExpressionStatement
                expression: AssignmentExpression
                  leftHandSide: IndexExpression
                    target: SimpleIdentifier
                      token: intList
                    leftBracket: [
                    index: SimpleIdentifier
                      token: x
                    rightBracket: ]
                  operator: =
                  rightHandSide: IntegerLiteral
                    literal: 0
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_assignment_trailing_identifier_no_comma_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x y] = 0; }
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
              ExpressionStatement
                expression: AssignmentExpression
                  leftHandSide: IndexExpression
                    target: SimpleIdentifier
                      token: intList
                    leftBracket: [
                    index: SimpleIdentifier
                      token: x
                    rightBracket: ]
                  operator: =
                  rightHandSide: IntegerLiteral
                    literal: 0
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedToken, 16, 6),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_block() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_break() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedToken, 16, 5),
      error(diag.expectedToken, 14, 1),
      error(diag.breakOutsideOfLoop, 16, 5),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 16, 8),
      error(diag.expectedToken, 14, 1),
      error(diag.continueOutsideOfLoop, 16, 8),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_do() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 16, 2),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_index_partial_identifier_for() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 16, 3),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: x
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: y
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_if() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 16, 2),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BooleanLiteral
                  literal: true
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              LabeledStatement
                labels
                  Label
                    name: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 16, 3),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  returnType: NamedType
                    name: int
                  name: f
                  functionExpression: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 16, 4),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
                  returnType: NamedType
                    name: void
                  name: f
                  functionExpression: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedToken, 16, 3),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_return() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 16, 6),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_identifier_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedToken, 16, 6),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: x
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_try() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 16, 3),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_identifier_while() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[x while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 16, 5),
      error(diag.expectedToken, 14, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: x
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_open_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedToken, 28, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: FunctionExpressionInvocation
                    function: SimpleIdentifier
                      token: assert
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        BooleanLiteral
                          literal: true
                      rightParenthesis: )
                  rightBracket: ] <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_open_block() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.expectedToken, 16, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SetOrMapLiteral
                    leftBracket: {
                    rightBracket: }
                    isMap: false
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_index_partial_open_break() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 15, 5),
      error(diag.expectedToken, 13, 1),
      error(diag.breakOutsideOfLoop, 15, 5),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_open_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 15, 8),
      error(diag.expectedToken, 15, 8),
      error(diag.expectedToken, 13, 1),
      error(diag.continueOutsideOfLoop, 15, 8),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_open_do() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 2),
      error(diag.expectedToken, 15, 2),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_open_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ }
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_index_partial_open_for() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedToken, 15, 3),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: x
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: y
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_open_if() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 15, 2),
      error(diag.expectedToken, 15, 2),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: BooleanLiteral
                  literal: true
                rightParenthesis: )
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_open_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 16, 1),
      error(diag.unexpectedToken, 16, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: l
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              ExpressionStatement
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_open_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.namedFunctionExpression, 19, 1),
      error(diag.expectedToken, 24, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_index_partial_open_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.namedFunctionExpression, 20, 1),
      error(diag.expectedToken, 25, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_index_partial_open_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedToken, 15, 3),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_open_return() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.unexpectedToken, 15, 6),
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 21, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_index_partial_open_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 27, 1),
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
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SwitchExpression
                    switchKeyword: switch
                    leftParenthesis: (
                    expression: SimpleIdentifier
                      token: x
                    rightParenthesis: )
                    leftBracket: {
                    rightBracket: }
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_index_partial_open_try() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedToken, 15, 3),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_index_partial_open_while() {
    var parseResult = parseStringWithErrors(r'''
f() { intList[ while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 15, 5),
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
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: IndexExpression
                  target: SimpleIdentifier
                    token: intList
                  leftBracket: [
                  index: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightBracket: ] <synthetic>
                semicolon: ; <synthetic>
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }
}
