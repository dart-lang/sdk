// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReturnStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ReturnStatementTest extends ParserDiagnosticsTest {
  void test_return_statement_expression_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { return a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_block() {
    var parseResult = parseStringWithErrors(r'''
f() { return a {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_return_statement_expression_break() {
    var parseResult = parseStringWithErrors(r'''
f() { return a break; }
''');
    parseResult.assertErrors([
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_expression_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { return a continue; }
''');
    parseResult.assertErrors([
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_expression_do() {
    var parseResult = parseStringWithErrors(r'''
f() { return a do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { return a }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_return_statement_expression_for() {
    var parseResult = parseStringWithErrors(r'''
f() { return a for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_if() {
    var parseResult = parseStringWithErrors(r'''
f() { return a if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { return a l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { return a int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { return a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { return a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_return() {
    var parseResult = parseStringWithErrors(r'''
f() { return a return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_expression_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { return a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_try() {
    var parseResult = parseStringWithErrors(r'''
f() { return a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_expression_while() {
    var parseResult = parseStringWithErrors(r'''
f() { return a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SimpleIdentifier
                  token: a
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

  void test_return_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { return assert (true); }
''');
    parseResult.assertErrors([]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: FunctionExpressionInvocation
                  function: SimpleIdentifier
                    token: assert
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() { return {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_return_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() { return break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { return continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 8),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() { return do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 2),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
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

  void test_return_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { return }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 1),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_return_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() { return for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
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

  void test_return_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() { return if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 2),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
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

  void test_return_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { return l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.missingIdentifier, 14, 1),
      error(diag.unexpectedToken, 14, 1),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: l
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

  void test_return_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { return int f() {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 17, 1),
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
              ReturnStatement
                returnKeyword: return
                expression: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
                  body: BlockFunctionBody
                    block: Block
                      leftBracket: {
                      rightBracket: }
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_return_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { return void f() {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 18, 1),
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
              ReturnStatement
                returnKeyword: return
                expression: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
                  body: BlockFunctionBody
                    block: Block
                      leftBracket: {
                      rightBracket: }
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_return_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { return var x; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
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

  void test_return_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() { return return; }
''');
    parseResult.assertErrors([
      error(diag.unexpectedToken, 13, 6),
      error(diag.missingIdentifier, 19, 1),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_return_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { return switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 25, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
                expression: SwitchExpression
                  switchKeyword: switch
                  leftParenthesis: (
                  expression: SimpleIdentifier
                    token: x
                  rightParenthesis: )
                  leftBracket: {
                  rightBracket: }
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_return_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() { return try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 3),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
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

  void test_return_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() { return while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 13, 5),
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
              ReturnStatement
                returnKeyword: return
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
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
