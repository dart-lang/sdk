// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 32, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 17, 5),
      error(diag.expectedToken, 15, 1),
      error(diag.breakOutsideOfLoop, 17, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 17, 8),
      error(diag.expectedToken, 15, 1),
      error(diag.continueOutsideOfLoop, 17, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 17, 2),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 17, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 17, 2),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 18, 1),
      error(diag.unexpectedToken, 18, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.namedFunctionExpression, 21, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.namedFunctionExpression, 22, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 17, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.unexpectedToken, 17, 6),
      error(diag.missingIdentifier, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 17, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 17, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_condition_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { assert (a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 6),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 5),
      error(diag.expectedToken, 6, 6),
      error(diag.breakOutsideOfLoop, 13, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 8),
      error(diag.expectedToken, 6, 6),
      error(diag.continueOutsideOfLoop, 13, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 2),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 2),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.expectedToken, 6, 6),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { assert int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 4),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 6),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 6),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 5),
      error(diag.expectedToken, 6, 6),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 30, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 15, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 2),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 15, 2),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( int f() {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( void f() {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.unexpectedToken, 15, 6),
      error(diag.missingIdentifier, 21, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( switch (x) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 15, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 15, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 17, 1),
      error(diag.breakOutsideOfLoop, 19, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 17, 1),
      error(diag.continueOutsideOfLoop, 19, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_message_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) assert (true); }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) break; }
''');
    parseResult.assertErrors([
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) continue; }
''');
    parseResult.assertErrors([
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) do {} while (true); }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) for (var x in y) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) if (true) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) l: {} }
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) int f() {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) void f() {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) var x; }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) return; }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) switch (x) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) try {} finally {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b) while (true) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
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
                    label: SimpleIdentifier
                      token: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_assert_statement_trailingComma_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { assert (a, b, while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
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
