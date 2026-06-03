// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[] = 0; }
//            ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ ] = 0; }
//             ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x,y] = 0; }
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x,] = 0; }
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x y] = 0; }
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x assert (true); }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x break; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^
// [diag.expectedToken] Expected to find ']'.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x continue; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^^^^
// [diag.expectedToken] Expected to find ']'.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x do {} while (true); }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x for (var x in y) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x if (true) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x l: {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x int f() {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x void f() {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x var x; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x return; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x switch (x) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x try {} finally {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[x while (true) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^
// [diag.expectedToken] Expected to find ']'.
//              ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ assert (true); }
//                          ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ break; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ continue; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ do {} while (true); }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ for (var x in y) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ if (true) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ l: {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedToken] Expected to find ']'.
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ int f() {} }
//                 ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ void f() {} }
//                  ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ var x; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ return; }
//             ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ switch (x) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ try {} finally {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { intList[ while (true) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ']'.
//             ^
// [diag.expectedToken] Expected to find ']'.
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
