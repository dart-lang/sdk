// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ForStatementTest extends ParserDiagnosticsTest {
  void test_for_statement_emptyParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for () assert (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for () {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_for_statement_emptyParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for () break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_emptyParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for () continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_emptyParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for () do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for () }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 13, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_emptyParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for () for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for () if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for () l: {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for () int f() {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for () void f() {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for () var x; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for () return; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_emptyParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for () switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for () try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_emptyParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for () while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 11, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: )
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

  void test_for_statement_equals_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 34, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: FunctionExpressionInvocation
                          function: SimpleIdentifier
                            token: assert
                          argumentList: ArgumentList
                            leftParenthesis: (
                            arguments
                              BooleanLiteral
                                literal: true
                            rightParenthesis: )
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SetOrMapLiteral
                          leftBracket: {
                          rightBracket: }
                          isMap: false
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 19, 8),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 8),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.missingIdentifier, 19, 2),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 2),
      error(diag.missingIdentifier, 39, 1),
      error(diag.expectedToken, 37, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = }
''');
    parseResult.assertErrors([
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.missingIdentifier, 19, 3),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 3),
      error(diag.missingIdentifier, 39, 1),
      error(diag.expectedToken, 37, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 19, 2),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 2),
      error(diag.missingIdentifier, 32, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.colonInPlaceOfIn, 20, 1),
      error(diag.initializedVariableInForEach, 17, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: i
                  inKeyword: :
                  iterable: SetOrMapLiteral
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

  void test_for_statement_equals_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.namedFunctionExpression, 23, 1),
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: FunctionExpression
                          parameters: FormalParameterList
                            leftParenthesis: (
                            rightParenthesis: )
                          body: BlockFunctionBody
                            block: Block
                              leftBracket: {
                              rightBracket: }
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.namedFunctionExpression, 24, 1),
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 31, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: FunctionExpression
                          parameters: FormalParameterList
                            leftParenthesis: (
                            rightParenthesis: )
                          body: BlockFunctionBody
                            block: Block
                              leftBracket: {
                              rightBracket: }
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingIdentifier, 19, 3),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 3),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.unexpectedToken, 19, 6),
      error(diag.missingIdentifier, 25, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SwitchExpression
                          switchKeyword: switch
                          leftParenthesis: (
                          expression: SimpleIdentifier
                            token: x
                          rightParenthesis: )
                          leftBracket: {
                          rightBracket: }
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 19, 3),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 3),
      error(diag.missingIdentifier, 37, 1),
      error(diag.expectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_equals_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 17, 1),
      error(diag.unexpectedToken, 19, 5),
      error(diag.missingIdentifier, 35, 1),
      error(diag.expectedToken, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: SimpleIdentifier
                          token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 37, 1),
      error(diag.expectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: FunctionExpressionInvocation
                    function: SimpleIdentifier
                      token: assert
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        BooleanLiteral
                          literal: true
                      rightParenthesis: )
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SetOrMapLiteral
                    leftBracket: {
                    rightBracket: }
                    isMap: false
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 22, 5),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 22, 8),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 8),
      error(diag.missingIdentifier, 32, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.missingIdentifier, 22, 2),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 2),
      error(diag.missingIdentifier, 42, 1),
      error(diag.expectedToken, 40, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; }
''');
    parseResult.assertErrors([
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.missingIdentifier, 22, 3),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 3),
      error(diag.missingIdentifier, 42, 1),
      error(diag.expectedToken, 40, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 22, 2),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 2),
      error(diag.missingIdentifier, 35, 1),
      error(diag.expectedToken, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 23, 1),
      error(diag.unexpectedToken, 23, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: l
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.namedFunctionExpression, 26, 1),
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.namedFunctionExpression, 27, 1),
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 34, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 22, 3),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 3),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.unexpectedToken, 22, 6),
      error(diag.missingIdentifier, 28, 1),
      error(diag.missingIdentifier, 30, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 36, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SwitchExpression
                    switchKeyword: switch
                    leftParenthesis: (
                    expression: SimpleIdentifier
                      token: x
                    rightParenthesis: )
                    leftBracket: {
                    rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 22, 3),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 3),
      error(diag.missingIdentifier, 40, 1),
      error(diag.expectedToken, 38, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_firstSemicolon_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0; while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.missingIdentifier, 22, 5),
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 22, 5),
      error(diag.missingIdentifier, 38, 1),
      error(diag.expectedToken, 36, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 36, 1),
      error(diag.expectedToken, 34, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpressionInvocation
                    function: SimpleIdentifier
                      token: assert
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        BooleanLiteral
                          literal: true
                      rightParenthesis: )
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 22, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SetOrMapLiteral
                    leftBracket: {
                    rightBracket: }
                    isMap: false
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 5),
      error(diag.unexpectedToken, 21, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 8),
      error(diag.unexpectedToken, 21, 8),
      error(diag.missingIdentifier, 31, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 2),
      error(diag.unexpectedToken, 21, 2),
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.expectedToken, 19, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 3),
      error(diag.unexpectedToken, 21, 3),
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 2),
      error(diag.unexpectedToken, 21, 2),
      error(diag.missingIdentifier, 34, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.missingIdentifier, 22, 1),
      error(diag.unexpectedToken, 22, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: l
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.namedFunctionExpression, 25, 1),
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 32, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.namedFunctionExpression, 26, 1),
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 3),
      error(diag.unexpectedToken, 21, 3),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.unexpectedToken, 21, 6),
      error(diag.missingIdentifier, 27, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SwitchExpression
                    switchKeyword: switch
                    leftParenthesis: (
                    expression: SimpleIdentifier
                      token: x
                    rightParenthesis: )
                    leftBracket: {
                    rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 3),
      error(diag.unexpectedToken, 21, 3),
      error(diag.missingIdentifier, 39, 1),
      error(diag.expectedToken, 37, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_initializer_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0 while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 21, 5),
      error(diag.unexpectedToken, 21, 5),
      error(diag.missingIdentifier, 37, 1),
      error(diag.expectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_for_statement_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_for_statement_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 5),
      error(diag.breakOutsideOfLoop, 10, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 8),
      error(diag.continueOutsideOfLoop, 10, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_for_statement_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_for_statement_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_for_statement_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_for_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_for_statement_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_for_statement_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_for_statement_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_for_statement_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_for_statement_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 10, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForPartsWithExpression
                  leftSeparator: ; <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
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

  void test_for_statement_leftParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( assert (true); }
''');
    parseResult.assertErrors([
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: FunctionExpressionInvocation
                    function: SimpleIdentifier
                      token: assert
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        BooleanLiteral
                          literal: true
                      rightParenthesis: )
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 13, 1),
      error(diag.missingIdentifier, 15, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SetOrMapLiteral
                    leftBracket: {
                    rightBracket: }
                    isMap: false
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 12, 5),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 12, 8),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 8),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 12, 2),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 2),
      error(diag.missingIdentifier, 32, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.missingIdentifier, 12, 3),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 3),
      error(diag.missingIdentifier, 32, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 12, 2),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 2),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.colonInPlaceOfIn, 13, 1),
      error(diag.missingIdentifier, 18, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: l
                  inKeyword: :
                  iterable: SetOrMapLiteral
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

  void test_for_statement_leftParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.expectedToken, 21, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    type: NamedType
                      name: int
                    variables
                      VariableDeclaration
                        name: f
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 17, 1),
      error(diag.expectedToken, 22, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    type: NamedType
                      name: void
                    variables
                      VariableDeclaration
                        name: f
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( var x; }
''');
    parseResult.assertErrors([
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.unexpectedToken, 12, 6),
      error(diag.missingIdentifier, 18, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedToken, 24, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SwitchExpression
                    switchKeyword: switch
                    leftParenthesis: (
                    expression: SimpleIdentifier
                      token: x
                    rightParenthesis: )
                    leftBracket: {
                    rightBracket: }
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 12, 3),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 3),
      error(diag.missingIdentifier, 30, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_leftParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 12, 5),
      error(diag.expectedToken, 10, 1),
      error(diag.unexpectedToken, 12, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithExpression
                  initialization: SimpleIdentifier
                    token: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) assert (true); }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) break; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) continue; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) do {} while (true); }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) }
''');
    parseResult.assertErrors([
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) for (var x in y) {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) if (true) {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) l: {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) int f() {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) void f() {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) var x; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) return; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) switch (x) {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) try {} finally {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_rightParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;;) while (true) {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: )
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

  void test_for_statement_secondSemicolon_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.unexpectedToken, 36, 1),
      error(diag.missingIdentifier, 38, 1),
      error(diag.expectedToken, 36, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    FunctionExpressionInvocation
                      function: SimpleIdentifier
                        token: assert
                      argumentList: ArgumentList
                        leftParenthesis: (
                        arguments
                          BooleanLiteral
                            literal: true
                        rightParenthesis: )
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SetOrMapLiteral
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

  void test_for_statement_secondSemicolon_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 23, 5),
      error(diag.unexpectedToken, 23, 5),
      error(diag.missingIdentifier, 30, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 23, 8),
      error(diag.unexpectedToken, 23, 8),
      error(diag.missingIdentifier, 33, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.missingIdentifier, 23, 2),
      error(diag.unexpectedToken, 23, 2),
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 41, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; }
''');
    parseResult.assertErrors([
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.missingIdentifier, 23, 3),
      error(diag.unexpectedToken, 23, 3),
      error(diag.missingIdentifier, 43, 1),
      error(diag.expectedToken, 41, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.missingIdentifier, 23, 2),
      error(diag.unexpectedToken, 23, 2),
      error(diag.missingIdentifier, 36, 1),
      error(diag.expectedToken, 34, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.unexpectedToken, 24, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: l
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.namedFunctionExpression, 27, 1),
      error(diag.missingIdentifier, 34, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    FunctionExpression
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

  void test_for_statement_secondSemicolon_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.namedFunctionExpression, 28, 1),
      error(diag.missingIdentifier, 35, 1),
      error(diag.expectedToken, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    FunctionExpression
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

  void test_for_statement_secondSemicolon_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 23, 3),
      error(diag.unexpectedToken, 23, 3),
      error(diag.missingIdentifier, 30, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.unexpectedToken, 23, 6),
      error(diag.missingIdentifier, 29, 1),
      error(diag.unexpectedToken, 29, 1),
      error(diag.missingIdentifier, 31, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 37, 1),
      error(diag.expectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SwitchExpression
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

  void test_for_statement_secondSemicolon_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.missingIdentifier, 23, 3),
      error(diag.unexpectedToken, 23, 3),
      error(diag.missingIdentifier, 41, 1),
      error(diag.expectedToken, 39, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_secondSemicolon_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i = 0;; while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.missingIdentifier, 23, 5),
      error(diag.unexpectedToken, 23, 5),
      error(diag.missingIdentifier, 39, 1),
      error(diag.expectedToken, 37, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                        equals: =
                        initializer: IntegerLiteral
                          literal: 0
                  leftSeparator: ;
                  rightSeparator: ;
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 15, 6),
      error(diag.expectedToken, 11, 3),
      error(diag.missingIdentifier, 30, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpressionInvocation
                    function: SimpleIdentifier
                      token: assert
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        BooleanLiteral
                          literal: true
                      rightParenthesis: )
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 11, 3),
      error(diag.expectedToken, 16, 1),
      error(diag.missingIdentifier, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SetOrMapLiteral
                    leftBracket: {
                    rightBracket: }
                    isMap: false
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 15, 8),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 8),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 2),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 2),
      error(diag.missingIdentifier, 35, 1),
      error(diag.expectedToken, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedToken, 11, 3),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
              ExpressionStatement
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
              ExpressionStatement
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 3),
      error(diag.missingIdentifier, 35, 1),
      error(diag.expectedToken, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 15, 2),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 2),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.colonInPlaceOfIn, 16, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: l
                  inKeyword: :
                  iterable: SetOrMapLiteral
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

  void test_for_statement_var_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.varAndType, 11, 3),
      error(diag.expectedToken, 19, 1),
      error(diag.expectedToken, 24, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    type: NamedType
                      name: int
                    variables
                      VariableDeclaration
                        name: f
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.varAndType, 11, 3),
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    type: NamedType
                      name: void
                    variables
                      VariableDeclaration
                        name: f
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.duplicatedModifier, 15, 3),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: x
                  leftSeparator: ;
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.missingIdentifier, 15, 6),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 6),
      error(diag.missingIdentifier, 21, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 15, 6),
      error(diag.expectedToken, 11, 3),
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 29, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SwitchExpression
                    switchKeyword: switch
                    leftParenthesis: (
                    expression: SimpleIdentifier
                      token: x
                    rightParenthesis: )
                    leftBracket: {
                    rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 3),
      error(diag.missingIdentifier, 33, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_var_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 11, 3),
      error(diag.unexpectedToken, 15, 5),
      error(diag.missingIdentifier, 31, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: <empty> <synthetic>
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 32, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpressionInvocation
                    function: SimpleIdentifier
                      token: assert
                    argumentList: ArgumentList
                      leftParenthesis: (
                      arguments
                        BooleanLiteral
                          literal: true
                      rightParenthesis: )
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 18, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SetOrMapLiteral
                    leftBracket: {
                    rightBracket: }
                    isMap: false
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 5),
      error(diag.unexpectedToken, 17, 5),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 8),
      error(diag.unexpectedToken, 17, 8),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 2),
      error(diag.unexpectedToken, 17, 2),
      error(diag.missingIdentifier, 37, 1),
      error(diag.expectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 17, 1),
      error(diag.expectedToken, 15, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 3),
      error(diag.unexpectedToken, 17, 3),
      error(diag.missingIdentifier, 37, 1),
      error(diag.expectedToken, 35, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 2),
      error(diag.unexpectedToken, 17, 2),
      error(diag.missingIdentifier, 30, 1),
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
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.varAndType, 11, 3),
      error(diag.colonInPlaceOfIn, 18, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    type: NamedType
                      name: i
                    name: l
                  inKeyword: :
                  iterable: SetOrMapLiteral
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

  void test_for_statement_varAndIdentifier_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.varAndType, 11, 3),
      error(diag.expectedToken, 17, 3),
      error(diag.namedFunctionExpression, 21, 1),
      error(diag.expectedToken, 26, 1),
      error(diag.missingIdentifier, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    type: NamedType
                      name: i
                    variables
                      VariableDeclaration
                        name: int
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.namedFunctionExpression, 22, 1),
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 29, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: FunctionExpression
                    parameters: FormalParameterList
                      leftParenthesis: (
                      rightParenthesis: )
                    body: BlockFunctionBody
                      block: Block
                        leftBracket: {
                        rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 3),
      error(diag.unexpectedToken, 17, 3),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.unexpectedToken, 17, 6),
      error(diag.missingIdentifier, 23, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ;
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.expectedToken, 29, 1),
      error(diag.missingIdentifier, 31, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SwitchExpression
                    switchKeyword: switch
                    leftParenthesis: (
                    expression: SimpleIdentifier
                      token: x
                    rightParenthesis: )
                    leftBracket: {
                    rightBracket: }
                  rightSeparator: ; <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 3),
      error(diag.unexpectedToken, 17, 3),
      error(diag.missingIdentifier, 35, 1),
      error(diag.expectedToken, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_for_statement_varAndIdentifier_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var i while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 17, 5),
      error(diag.unexpectedToken, 17, 5),
      error(diag.missingIdentifier, 33, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForPartsWithDeclarations
                  variables: VariableDeclarationList
                    keyword: var
                    variables
                      VariableDeclaration
                        name: i
                  leftSeparator: ; <synthetic>
                  condition: SimpleIdentifier
                    token: <empty> <synthetic>
                  rightSeparator: ; <synthetic>
                  updaters
                    SimpleIdentifier
                      token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }
}
