// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(YieldStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class YieldStatementTest extends ParserDiagnosticsTest {
  void test_yield_statement_expression_assert() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a assert (true); }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_block() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_yield_statement_expression_break() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a break; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_expression_continue() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a continue; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_expression_do() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a do {} while (true); }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_eof() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_yield_statement_expression_for() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a for (var x in y) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_if() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a if (true) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a l: {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a int f() {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a void f() {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a var x; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_return() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a return; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_expression_switch() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a switch (x) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_try() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a try {} finally {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_expression_while() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield a while (true) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield assert (true); }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_yield_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield break; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield continue; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield do {} while (true); }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_yield_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield for (var x in y) {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield if (true) {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 19, 1),
      error(diag.unexpectedToken, 19, 1),
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield int f() {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield void f() {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 23, 1),
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield var x; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield return; }
''');
    parseResult.assertErrors([
      error(diag.unexpectedToken, 18, 6),
      error(diag.missingIdentifier, 24, 1),
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield switch (x) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield try {} finally {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield while (true) {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
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

  void test_yield_statement_star_assert() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * assert (true); }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_block() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 21, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_yield_statement_star_break() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * break; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_star_continue() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * continue; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_star_do() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * do {} while (true); }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_eof() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_yield_statement_star_expression_assert() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a assert (true); }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_block() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_yield_statement_star_expression_break() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a break; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_star_expression_continue() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a continue; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_star_expression_do() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a do {} while (true); }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_eof() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_yield_statement_star_expression_for() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a for (var x in y) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_if() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a if (true) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a l: {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a int f() {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a void f() {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a var x; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_return() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a return; }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_star_expression_switch() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a switch (x) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_try() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a try {} finally {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_expression_while() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * a while (true) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_for() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * for (var x in y) {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_if() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * if (true) {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * l: {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * int f() {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * void f() {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * var x; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_return() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * return; }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_yield_statement_star_switch() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * switch (x) {} }
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_try() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * try {} finally {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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

  void test_yield_statement_star_while() {
    var parseResult = parseStringWithErrors(r'''
f() sync* { yield * while (true) {} }
''');
    parseResult.assertErrors([
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
          keyword: sync
          star: *
          block: Block
            leftBracket: {
            statements
              YieldStatement
                yieldKeyword: yield
                star: *
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
