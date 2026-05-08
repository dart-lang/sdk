// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.breakOutsideOfLoop, 21, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.continueOutsideOfLoop, 21, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 19, 1),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_condition_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 24, 1),
      error(diag.expectedToken, 22, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.missingIdentifier, 16, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 19, 1),
      error(diag.expectedToken, 17, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 29, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 9, 1),
      error(diag.expectedToken, 6, 2),
      error(diag.expectedToken, 9, 1),
      error(diag.expectedToken, 9, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 29, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 22, 1),
      error(diag.expectedToken, 20, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
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
              DoStatement
                doKeyword: do
                body: LabeledStatement
                  labels
                    Label
                      label: SimpleIdentifier
                        token: l
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
    var parseResult = parseStringWithErrors(r'''
f() { do int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.missingIdentifier, 16, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 17, 1),
      error(diag.expectedToken, 15, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 27, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 25, 1),
      error(diag.expectedToken, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 28, 0),
      error(diag.expectedToken, 28, 0),
      error(diag.missingIdentifier, 28, 0),
      error(diag.expectedToken, 26, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 16, 0),
      error(diag.expectedToken, 16, 0),
      error(diag.missingIdentifier, 16, 0),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 20, 0),
      error(diag.expectedToken, 20, 0),
      error(diag.missingIdentifier, 20, 0),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedToken, 23, 0),
      error(diag.expectedToken, 23, 0),
      error(diag.missingIdentifier, 23, 0),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 33, 0),
      error(diag.expectedToken, 33, 0),
      error(diag.missingIdentifier, 33, 0),
      error(diag.expectedToken, 31, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 13, 0),
      error(diag.expectedToken, 13, 0),
      error(diag.missingIdentifier, 13, 0),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 33, 0),
      error(diag.expectedToken, 33, 0),
      error(diag.missingIdentifier, 33, 0),
      error(diag.expectedToken, 31, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 26, 0),
      error(diag.expectedToken, 26, 0),
      error(diag.missingIdentifier, 26, 0),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 19, 0),
      error(diag.expectedToken, 19, 0),
      error(diag.missingIdentifier, 19, 0),
      error(diag.expectedToken, 17, 1),
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
              DoStatement
                doKeyword: do
                body: Block
                  leftBracket: {
                  statements
                    LabeledStatement
                      labels
                        Label
                          label: SimpleIdentifier
                            token: l
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
    var parseResult = parseStringWithErrors(r'''
f() { do { int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 24, 0),
      error(diag.expectedToken, 24, 0),
      error(diag.missingIdentifier, 24, 0),
      error(diag.expectedToken, 22, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 25, 0),
      error(diag.expectedToken, 25, 0),
      error(diag.missingIdentifier, 25, 0),
      error(diag.expectedToken, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 20, 0),
      error(diag.expectedToken, 20, 0),
      error(diag.missingIdentifier, 20, 0),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 21, 0),
      error(diag.expectedToken, 21, 0),
      error(diag.missingIdentifier, 21, 0),
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 27, 0),
      error(diag.expectedToken, 27, 0),
      error(diag.missingIdentifier, 27, 0),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedToken, 31, 0),
      error(diag.expectedToken, 31, 0),
      error(diag.missingIdentifier, 31, 0),
      error(diag.expectedToken, 29, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do { while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 29, 0),
      error(diag.expectedToken, 29, 0),
      error(diag.missingIdentifier, 29, 0),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 35, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 20, 5),
      error(diag.expectedToken, 18, 1),
      error(diag.breakOutsideOfLoop, 20, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 20, 8),
      error(diag.expectedToken, 18, 1),
      error(diag.continueOutsideOfLoop, 20, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 20, 2),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 20, 3),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 20, 2),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 21, 1),
      error(diag.unexpectedToken, 21, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.namedFunctionExpression, 24, 1),
      error(diag.expectedToken, 29, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.namedFunctionExpression, 25, 1),
      error(diag.expectedToken, 30, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 20, 3),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.unexpectedToken, 20, 6),
      error(diag.missingIdentifier, 26, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 32, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.missingIdentifier, 20, 3),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.missingIdentifier, 20, 5),
      error(diag.expectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 6),
      error(diag.expectedToken, 12, 6),
      error(diag.missingIdentifier, 12, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.expectedToken, 12, 5),
      error(diag.missingIdentifier, 12, 5),
      error(diag.expectedToken, 10, 1),
      error(diag.breakOutsideOfLoop, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 8),
      error(diag.expectedToken, 12, 8),
      error(diag.missingIdentifier, 12, 8),
      error(diag.expectedToken, 10, 1),
      error(diag.continueOutsideOfLoop, 12, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 2),
      error(diag.expectedToken, 12, 2),
      error(diag.missingIdentifier, 12, 2),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 2),
      error(diag.expectedToken, 12, 2),
      error(diag.missingIdentifier, 12, 2),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_rightBrace_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { do {} int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 4),
      error(diag.expectedToken, 12, 4),
      error(diag.missingIdentifier, 12, 4),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 6),
      error(diag.expectedToken, 12, 6),
      error(diag.missingIdentifier, 12, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 6),
      error(diag.expectedToken, 12, 6),
      error(diag.missingIdentifier, 12, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 23, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.breakOutsideOfLoop, 22, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.continueOutsideOfLoop, 22, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while (a) while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 20, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 6),
      error(diag.missingIdentifier, 18, 6),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 18, 1),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 5),
      error(diag.missingIdentifier, 18, 5),
      error(diag.expectedToken, 12, 5),
      error(diag.breakOutsideOfLoop, 18, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 8),
      error(diag.missingIdentifier, 18, 8),
      error(diag.expectedToken, 12, 5),
      error(diag.continueOutsideOfLoop, 18, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 2),
      error(diag.missingIdentifier, 18, 2),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 18, 1),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 3),
      error(diag.missingIdentifier, 18, 3),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 2),
      error(diag.missingIdentifier, 18, 2),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 18, 1),
      error(diag.expectedToken, 12, 5),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_do_statement_while_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { do {} while int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 3),
      error(diag.missingIdentifier, 18, 3),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 4),
      error(diag.missingIdentifier, 18, 4),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 3),
      error(diag.missingIdentifier, 18, 3),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 6),
      error(diag.missingIdentifier, 18, 6),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 6),
      error(diag.missingIdentifier, 18, 6),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 3),
      error(diag.missingIdentifier, 18, 3),
      error(diag.expectedToken, 12, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { do {} while while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 5),
      error(diag.missingIdentifier, 18, 5),
      error(diag.expectedToken, 12, 5),
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
