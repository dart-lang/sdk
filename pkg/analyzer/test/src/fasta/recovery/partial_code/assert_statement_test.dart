// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssertStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssertStatementTest extends ParserDiagnosticsTest {
  void test_assert_statement_comma_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, assert (true); }
//                            ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: FunctionExpressionInvocation
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

  void test_assert_statement_comma_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_comma_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, break; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_comma_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, continue; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_comma_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, do {} while (true); }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^
// [diag.missingIdentifier] Expected an identifier.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_comma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_comma_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, for (var x in y) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_comma_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, if (true) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^
// [diag.missingIdentifier] Expected an identifier.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_comma_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, l: {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_comma_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, int f() {} }
//                   ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: FunctionExpression
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

  void test_assert_statement_comma_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, void f() {} }
//                    ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: FunctionExpression
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

  void test_assert_statement_comma_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, var x; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_comma_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, return; }
//               ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                     ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_comma_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, switch (x) {} }
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SwitchExpression
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

  void test_assert_statement_comma_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, try {} finally {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_comma_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, while (true) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//               ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
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

  void test_assert_statement_condition_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a assert (true); }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a break; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a continue; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a do {} while (true); }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_condition_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a for (var x in y) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a if (true) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a l: {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a int f() {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a void f() {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a var x; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a return; }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a switch (x) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a try {} finally {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_condition_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a while (true) {} }
//            ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert assert (true); }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert break; }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
// [diag.expectedToken] Expected to find '('.
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert continue; }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^^^
// [diag.expectedToken] Expected to find '('.
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert do {} while (true); }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_keyword_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert for (var x in y) {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert if (true) {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert l: {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert int f() {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert void f() {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert var x; }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert return; }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert switch (x) {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert try {} finally {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_keyword_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert while (true) {} }
//    ^^^^^^
// [diag.expectedToken] Expected to find ';'.
//           ^^^^^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( assert (true); }
//                          ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( break; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( continue; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( do {} while (true); }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^
// [diag.missingIdentifier] Expected an identifier.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_leftParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( for (var x in y) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( if (true) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^
// [diag.missingIdentifier] Expected an identifier.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( l: {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//              ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( int f() {} }
//                 ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( void f() {} }
//                  ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( var x; }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( return; }
//             ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                   ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_leftParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( switch (x) {} }
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( try {} finally {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_leftParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert ( while (true) {} }
//           ^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
//             ^
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
              AssertStatement
                assertKeyword: assert
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

  void test_assert_statement_message_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b assert (true); }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_message_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b break; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^^^
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_message_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b continue; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_message_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b do {} while (true); }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_message_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b for (var x in y) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b if (true) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b l: {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b int f() {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b void f() {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b var x; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b return; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_message_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b switch (x) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b try {} finally {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_message_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b while (true) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) assert (true); }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_rightParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) break; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: )
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_rightParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) continue; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^^^^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: )
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_rightParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) do {} while (true); }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: )
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_rightParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) for (var x in y) {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) if (true) {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) l: {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) int f() {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) void f() {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) var x; }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) return; }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: )
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_rightParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) switch (x) {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) try {} finally {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_rightParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b) while (true) {} }
//                ^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, assert (true); }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_trailingComma_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, break; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_trailingComma_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, continue; }
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^^^^^^^^
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_trailingComma_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, do {} while (true); }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_assert_statement_trailingComma_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, for (var x in y) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, if (true) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, l: {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, int f() {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, void f() {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, var x; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, return; }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
                rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_assert_statement_trailingComma_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, switch (x) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, try {} finally {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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

  void test_assert_statement_trailingComma_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { assert (a, b, while (true) {} }
//                ^
// [diag.expectedToken] Expected to find ';'.
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
              AssertStatement
                assertKeyword: assert
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                comma: ,
                message: SimpleIdentifier
                  token: b
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
