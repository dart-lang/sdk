// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContinueStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ContinueStatementTest extends ParserDiagnosticsTest {
  void test_continue_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { continue assert (true); }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() { continue {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_continue_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() { continue break; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_continue_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { continue continue; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_continue_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() { continue do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { continue }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_continue_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() { continue for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() { continue if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { continue l: {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: l
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

  void test_continue_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { continue int f() {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: int
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

  void test_continue_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { continue void f() {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { continue var x; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() { continue return; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_continue_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { continue switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() { continue try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() { continue while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
      error(diag.expectedToken, 6, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ContinueStatement
                continueKeyword: continue
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

  void test_continue_statement_label_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a assert (true); }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_block() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_continue_statement_label_break() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a break; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_continue_statement_label_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a continue; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_continue_statement_label_do() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_continue_statement_label_for() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_if() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a l: {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a void f() {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a var x; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_return() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a return; }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_continue_statement_label_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_try() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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

  void test_continue_statement_label_while() {
    var parseResult = parseStringWithErrors(r'''
f() { continue a while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.continueOutsideOfLoop, 6, 8),
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
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
