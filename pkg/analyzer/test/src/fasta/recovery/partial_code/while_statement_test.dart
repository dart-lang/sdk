// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WhileStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WhileStatementTest extends ParserDiagnosticsTest {
  void test_while_statement_condition_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a assert (true); }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: AssertStatement
                  assertKeyword: assert
                  leftParenthesis: (
                  condition: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_condition_block() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a {} }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_while_statement_condition_break() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a break; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_condition_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a continue; }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_condition_do() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a do {} while (true); }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_condition_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_condition_for() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a for (var x in y) {} }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_condition_if() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a if (true) {} }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: IfStatement
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

  void test_while_statement_condition_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a l: {} }
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
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: LabeledStatement
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

  void test_while_statement_condition_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a int f() {} }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_condition_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a void f() {} }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_condition_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_condition_return() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a return; }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_condition_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: SwitchStatement
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

  void test_while_statement_condition_try() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 33, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: TryStatement
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

  void test_while_statement_condition_while() {
    var parseResult = parseStringWithErrors(r'''
f() { while (a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 31, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                body: WhileStatement
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

  void test_while_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { while assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 6),
      error(diag.missingIdentifier, 12, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: AssertStatement
                  assertKeyword: assert
                  leftParenthesis: (
                  condition: BooleanLiteral
                    literal: true
                  rightParenthesis: )
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() { while {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_while_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() { while break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.missingIdentifier, 12, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { while continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 8),
      error(diag.missingIdentifier, 12, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() { while do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 2),
      error(diag.missingIdentifier, 12, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { while }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() { while for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() { while if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 2),
      error(diag.missingIdentifier, 12, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: IfStatement
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

  void test_while_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { while l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 12, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: LabeledStatement
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

  void test_while_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { while int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { while void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 4),
      error(diag.missingIdentifier, 12, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { while var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() { while return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 6),
      error(diag.missingIdentifier, 12, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { while switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 6),
      error(diag.missingIdentifier, 12, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: SwitchStatement
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

  void test_while_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() { while try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 3),
      error(diag.missingIdentifier, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: TryStatement
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

  void test_while_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() { while while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 5),
      error(diag.missingIdentifier, 12, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: ( <synthetic>
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: WhileStatement
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

  void test_while_statement_leftParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
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
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( {} }
''');
    parseResult.assertErrors([
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 14, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 14, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( }
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
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 14, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
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
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 14, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: IfStatement
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

  void test_while_statement_leftParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 14, 1),
      error(diag.unexpectedToken, 15, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: l
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_while_statement_leftParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.namedFunctionExpression, 18, 1),
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
              WhileStatement
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
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.namedFunctionExpression, 19, 1),
      error(diag.missingIdentifier, 26, 1),
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
              WhileStatement
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
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 14, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: VariableDeclarationStatement
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.unexpectedToken, 14, 6),
      error(diag.missingIdentifier, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 28, 1),
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
              WhileStatement
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
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_while_statement_leftParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 14, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: TryStatement
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

  void test_while_statement_leftParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() { while ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: WhileStatement
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
