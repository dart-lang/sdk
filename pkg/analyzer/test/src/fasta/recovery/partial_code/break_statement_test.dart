// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BreakStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BreakStatementTest extends ParserDiagnosticsTest {
  void test_break_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { break assert (true); }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() { break {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_break_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() { break break; }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
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
              BreakStatement
                breakKeyword: break
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_break_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { break continue; }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
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
              BreakStatement
                breakKeyword: break
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_break_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() { break do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { break }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_break_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() { break for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() { break if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { break l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.unexpectedToken, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { break int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
                  token: int
                semicolon: ; <synthetic>
              FunctionDeclarationStatement
                functionDeclaration: FunctionDeclaration
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

  void test_break_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { break void f() {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { break var x; }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() { break return; }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_break_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { break switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() { break try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() { break while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.breakOutsideOfLoop, 6, 5),
      error(diag.expectedToken, 6, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
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

  void test_break_statement_label_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { break a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_block() {
    var parseResult = parseStringWithErrors(r'''
f() { break a {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_break_statement_label_break() {
    var parseResult = parseStringWithErrors(r'''
f() { break a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.breakOutsideOfLoop, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_break_statement_label_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { break a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.continueOutsideOfLoop, 14, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_break_statement_label_do() {
    var parseResult = parseStringWithErrors(r'''
f() { break a do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { break a }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_break_statement_label_for() {
    var parseResult = parseStringWithErrors(r'''
f() { break a for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_if() {
    var parseResult = parseStringWithErrors(r'''
f() { break a if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { break a l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { break a int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { break a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { break a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_return() {
    var parseResult = parseStringWithErrors(r'''
f() { break a return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
                  token: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_break_statement_label_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { break a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_try() {
    var parseResult = parseStringWithErrors(r'''
f() { break a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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

  void test_break_statement_label_while() {
    var parseResult = parseStringWithErrors(r'''
f() { break a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              BreakStatement
                breakKeyword: break
                label: SimpleIdentifier
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
}
