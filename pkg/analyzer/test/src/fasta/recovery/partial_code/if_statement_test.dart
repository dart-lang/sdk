// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IfStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IfStatementTest extends ParserDiagnosticsTest {
  void test_if_statement_condition_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 27, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: AssertStatement
                  assertKeyword: assert
                  leftParenthesis: (
                  condition: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_condition_block() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a {} }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_if_statement_condition_break() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_condition_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_condition_do() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a do {} while (true); }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: DoStatement
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

  void test_if_statement_condition_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a }
''');
    parseResult.assertErrors([
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_condition_for() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a for (var x in y) {} }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: ForStatement
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

  void test_if_statement_condition_if() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a if (true) {} }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: IfStatement
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

  void test_if_statement_condition_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a l: {} }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: LabeledStatement
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

  void test_if_statement_condition_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a int f() {} }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: FunctionDeclarationStatement
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

  void test_if_statement_condition_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: FunctionDeclarationStatement
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

  void test_if_statement_condition_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a var x; }
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
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_condition_return() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a return; }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_condition_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 26, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: SwitchStatement
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

  void test_if_statement_condition_try() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a try {} finally {} }
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: TryStatement
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

  void test_if_statement_condition_while() {
    var parseResult = parseStringWithErrors(r'''
f() { if (a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 28, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                thenStatement: WhileStatement
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

  void test_if_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { if assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 6),
      error(diag.missingIdentifier, 9, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: AssertStatement
                  assertKeyword: assert
                  leftParenthesis: (
                  condition: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() { if {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 1),
      error(diag.missingIdentifier, 9, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_if_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() { if break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 5),
      error(diag.missingIdentifier, 9, 5),
      error(diag.breakOutsideOfLoop, 9, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { if continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 8),
      error(diag.missingIdentifier, 9, 8),
      error(diag.continueOutsideOfLoop, 9, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() { if do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 2),
      error(diag.missingIdentifier, 9, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: DoStatement
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

  void test_if_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { if }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 1),
      error(diag.missingIdentifier, 9, 1),
      error(diag.expectedToken, 6, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() { if for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 3),
      error(diag.missingIdentifier, 9, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ForStatement
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

  void test_if_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() { if if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 2),
      error(diag.missingIdentifier, 9, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: IfStatement
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

  void test_if_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { if l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 1),
      error(diag.missingIdentifier, 9, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: LabeledStatement
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

  void test_if_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { if int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 3),
      error(diag.missingIdentifier, 9, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: FunctionDeclarationStatement
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

  void test_if_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { if void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 4),
      error(diag.missingIdentifier, 9, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: FunctionDeclarationStatement
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

  void test_if_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { if var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 3),
      error(diag.missingIdentifier, 9, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() { if return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 6),
      error(diag.missingIdentifier, 9, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { if switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 6),
      error(diag.missingIdentifier, 9, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: SwitchStatement
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

  void test_if_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() { if try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 3),
      error(diag.missingIdentifier, 9, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: TryStatement
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

  void test_if_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() { if while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 9, 5),
      error(diag.missingIdentifier, 9, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: WhileStatement
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

  void test_if_statement_leftParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 26, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: FunctionExpressionInvocation
                  function: SimpleIdentifier
                    token: assert
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                rightParenthesis: ) <synthetic>
                thenStatement: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.missingIdentifier, 14, 1),
      error(diag.expectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 11, 5),
      error(diag.breakOutsideOfLoop, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 11, 8),
      error(diag.continueOutsideOfLoop, 11, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 11, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: DoStatement
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

  void test_if_statement_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 11, 1),
      error(diag.missingIdentifier, 11, 1),
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: ForStatement
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

  void test_if_statement_leftParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 11, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: IfStatement
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

  void test_if_statement_leftParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.missingIdentifier, 12, 1),
      error(diag.expectedToken, 11, 1),
      error(diag.unexpectedToken, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: l
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_if_statement_leftParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.namedFunctionExpression, 15, 1),
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
                  body: BlockFunctionBody
                    block: Block
                      leftBracket: {
                      rightBracket: }
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.namedFunctionExpression, 16, 1),
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: FunctionExpression
                  parameters: FormalParameterList
                    leftParenthesis: (
                    rightParenthesis: )
                  body: BlockFunctionBody
                    block: Block
                      leftBracket: {
                      rightBracket: }
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.unexpectedToken, 11, 6),
      error(diag.missingIdentifier, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( switch (x) {} }
''');
    parseResult.assertErrors([
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
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SwitchExpression
                  switchKeyword: switch
                  leftParenthesis: (
                  expression: SimpleIdentifier
                    token: x
                  rightParenthesis: )
                  leftBracket: {
                  rightBracket: }
                rightParenthesis: ) <synthetic>
                thenStatement: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_if_statement_leftParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 11, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: TryStatement
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

  void test_if_statement_leftParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() { if ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 11, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              IfStatement
                ifKeyword: if
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                thenStatement: WhileStatement
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
