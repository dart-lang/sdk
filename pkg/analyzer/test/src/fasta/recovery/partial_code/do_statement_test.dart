// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DoStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DoStatementTest extends ParserDiagnosticsTest {
  void test_do_statement_condition_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a assert (true); }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_condition_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a break; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^^
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_condition_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a continue; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_condition_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a do {} while (true); }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_condition_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a for (var x in y) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a if (true) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a l: {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a int f() {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a void f() {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a var x; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a return; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_condition_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a switch (x) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a try {} finally {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_condition_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a while (true) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_keyword_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do assert (true); }
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: AssertStatement
                  assertKeyword: assert
                  leftParenthesis: (
                  condition: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  semicolon: ;
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do break; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do continue; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do do {} while (true); }
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: DoStatement
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do }
//    ^^
// [diag.expectedToken] Expected to find ';'.
//       ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do for (var x in y) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: ForStatement
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do if (true) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: IfStatement
                  ifKeyword: if
                  leftParenthesis: (
                  expression: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  thenStatement: Block
                    leftBracket: {
                    rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do l: {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: LabeledStatement
                  labels
                    Label
                      name: l
                      colon: :
                  statement: Block
                    leftBracket: {
                    rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do int f() {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: FunctionDeclarationStatement
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do void f() {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: FunctionDeclarationStatement
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do var x; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do return; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do switch (x) {} }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: SwitchStatement
                  switchKeyword: switch
                  leftParenthesis: (
                  expression: SimpleIdentifier
                    token: x
                  rightParenthesis: )
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do try {} finally {} }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: TryStatement
                  tryKeyword: try
                  body: Block
                    leftBracket: {
                    rightBracket: }
                  finallyKeyword: finally
                  finallyBlock: Block
                    leftBracket: {
                    rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_keyword_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do while (true) {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: WhileStatement
                  whileKeyword: while
                  leftParenthesis: (
                  condition: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  body: Block
                    leftBracket: {
                    rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_leftBrace_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { assert (true); }
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.expectedToken][column 28][length 0] Expected to find 'while'.
// [diag.expectedToken][column 28][length 0] Expected to find '('.
// [diag.missingIdentifier][column 28][length 0] Expected an identifier.
// [diag.expectedToken][column 28][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    AssertStatement
                      assertKeyword: assert
                      leftParenthesis: (
                      condition: BooleanLiteral
                        literal: true
                      rightParenthesis: )
                      semicolon: ;
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.expectedToken][column 16][length 0] Expected to find 'while'.
// [diag.expectedToken][column 16][length 0] Expected to find '('.
// [diag.missingIdentifier][column 16][length 0] Expected an identifier.
// [diag.expectedToken][column 16][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    Block
                      leftBracket: {
                      rightBracket: }
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { break; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
// [diag.expectedToken][column 20][length 0] Expected to find 'while'.
// [diag.expectedToken][column 20][length 0] Expected to find '('.
// [diag.missingIdentifier][column 20][length 0] Expected an identifier.
// [diag.expectedToken][column 20][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    BreakStatement
                      breakKeyword: break
                      semicolon: ;
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { continue; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.expectedToken][column 23][length 0] Expected to find 'while'.
// [diag.expectedToken][column 23][length 0] Expected to find '('.
// [diag.missingIdentifier][column 23][length 0] Expected an identifier.
// [diag.expectedToken][column 23][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    ContinueStatement
                      continueKeyword: continue
                      semicolon: ;
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { do {} while (true); }
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
// [diag.expectedToken][column 33][length 0] Expected to find 'while'.
// [diag.expectedToken][column 33][length 0] Expected to find '('.
// [diag.missingIdentifier][column 33][length 0] Expected an identifier.
// [diag.expectedToken][column 33][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { }
//         ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.expectedToken][column 13][length 0] Expected to find 'while'.
// [diag.expectedToken][column 13][length 0] Expected to find '('.
// [diag.missingIdentifier][column 13][length 0] Expected an identifier.
// [diag.expectedToken][column 13][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { for (var x in y) {} }
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
// [diag.expectedToken][column 33][length 0] Expected to find 'while'.
// [diag.expectedToken][column 33][length 0] Expected to find '('.
// [diag.missingIdentifier][column 33][length 0] Expected an identifier.
// [diag.expectedToken][column 33][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { if (true) {} }
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.expectedToken][column 26][length 0] Expected to find 'while'.
// [diag.expectedToken][column 26][length 0] Expected to find '('.
// [diag.missingIdentifier][column 26][length 0] Expected an identifier.
// [diag.expectedToken][column 26][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { l: {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedToken][column 19][length 0] Expected to find 'while'.
// [diag.expectedToken][column 19][length 0] Expected to find '('.
// [diag.missingIdentifier][column 19][length 0] Expected an identifier.
// [diag.expectedToken][column 19][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    LabeledStatement
                      labels
                        Label
                          name: l
                          colon: :
                      statement: Block
                        leftBracket: {
                        rightBracket: }
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { int f() {} }
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.expectedToken][column 24][length 0] Expected to find 'while'.
// [diag.expectedToken][column 24][length 0] Expected to find '('.
// [diag.missingIdentifier][column 24][length 0] Expected an identifier.
// [diag.expectedToken][column 24][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { void f() {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.expectedToken][column 25][length 0] Expected to find 'while'.
// [diag.expectedToken][column 25][length 0] Expected to find '('.
// [diag.missingIdentifier][column 25][length 0] Expected an identifier.
// [diag.expectedToken][column 25][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { var x; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
// [diag.expectedToken][column 20][length 0] Expected to find 'while'.
// [diag.expectedToken][column 20][length 0] Expected to find '('.
// [diag.missingIdentifier][column 20][length 0] Expected an identifier.
// [diag.expectedToken][column 20][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    VariableDeclarationStatement
                      variables: VariableDeclarationList
                        keyword: var
                        variables
                          VariableDeclaration
                            name: x
                      semicolon: ;
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { return; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.expectedToken][column 21][length 0] Expected to find 'while'.
// [diag.expectedToken][column 21][length 0] Expected to find '('.
// [diag.missingIdentifier][column 21][length 0] Expected an identifier.
// [diag.expectedToken][column 21][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    ReturnStatement
                      returnKeyword: return
                      semicolon: ;
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { switch (x) {} }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
// [diag.expectedToken][column 27][length 0] Expected to find 'while'.
// [diag.expectedToken][column 27][length 0] Expected to find '('.
// [diag.missingIdentifier][column 27][length 0] Expected an identifier.
// [diag.expectedToken][column 27][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    SwitchStatement
                      switchKeyword: switch
                      leftParenthesis: (
                      expression: SimpleIdentifier
                        token: x
                      rightParenthesis: )
                      leftBracket: {
                      rightBracket: }
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { try {} finally {} }
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
// [diag.expectedToken][column 31][length 0] Expected to find 'while'.
// [diag.expectedToken][column 31][length 0] Expected to find '('.
// [diag.missingIdentifier][column 31][length 0] Expected an identifier.
// [diag.expectedToken][column 31][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftBrace_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do { while (true) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
// [diag.expectedToken][column 29][length 0] Expected to find 'while'.
// [diag.expectedToken][column 29][length 0] Expected to find '('.
// [diag.missingIdentifier][column 29][length 0] Expected an identifier.
// [diag.expectedToken][column 29][length 1] Expected to find '}'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
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
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: } <synthetic>
''');
  }

  void test_do_statement_leftParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( assert (true); }
//                               ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: FunctionExpressionInvocation
                  function: SimpleIdentifier
                    token: assert
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( {} }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( break; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( continue; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( do {} while (true); }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( for (var x in y) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_leftParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( if (true) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_leftParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( l: {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ';'.
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: l
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_leftParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( int f() {} }
//                      ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                             ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
                  body: BlockFunctionBody
                    block: Block
                      leftBracket: {
                      rightBracket: }
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( void f() {} }
//                       ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
                  body: BlockFunctionBody
                    block: Block
                      leftBracket: {
                      rightBracket: }
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( var x; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_leftParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( return; }
//                  ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                        ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( switch (x) {} }
//                              ^
// [diag.expectedToken] Expected to find ';'.
//                                ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SwitchExpression
                  switchKeyword: switch
                  leftParenthesis: (
                  expression: SimpleIdentifier
                    token: x
                  rightParenthesis: )
                  leftBracket: {
                  rightBracket: }
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_leftParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( try {} finally {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_leftParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while ( while (true) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//                  ^
// [diag.expectedToken] Expected to find ')'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} assert (true); }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_rightBrace_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} break; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_rightBrace_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} continue; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_rightBrace_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} do {} while (true); }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_rightBrace_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} for (var x in y) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} if (true) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} l: {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} int f() {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} void f() {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} var x; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} return; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_rightBrace_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} switch (x) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} try {} finally {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.expectedToken] Expected to find 'while'.
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while <synthetic>
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_rightBrace_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (true) {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
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
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) assert (true); }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) break; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^^^
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) continue; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) do {} while (true); }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) for (var x in y) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) if (true) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) l: {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) int f() {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) void f() {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) var x; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) return; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) switch (x) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) try {} finally {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_rightParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while (a) while (true) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: )
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

  void test_do_statement_while_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while assert (true); }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_while_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while break; }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_while_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while continue; }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_while_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while do {} while (true); }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_do_statement_while_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while for (var x in y) {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while if (true) {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while l: {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while int f() {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while void f() {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while var x; }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while return; }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_do_statement_while_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while switch (x) {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while try {} finally {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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

  void test_do_statement_while_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { do {} while while (true) {} }
//          ^^^^^
// [diag.expectedToken] Expected to find ';'.
//                ^^^^^
// [diag.expectedToken] Expected to find '('.
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  rightBracket: }
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
