// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () assert (true); }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () break; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () continue; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () do {} while (true); }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//           ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () for (var x in y) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () if (true) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () l: {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
                      name: l
                      colon: :
                  statement: Block
                    leftBracket: {
                    rightBracket: }
            rightBracket: }
''');
  }

  void test_for_statement_emptyParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () int f() {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () void f() {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () var x; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () return; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () switch (x) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () try {} finally {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for () while (true) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//         ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = assert (true); }
//                              ^
// [diag.expectedToken] Expected to find ';'.
//                                ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = break; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = continue; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = do {} while (true); }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                                   ^
// [diag.expectedToken] Expected to find ';'.
//                                     ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = for (var x in y) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                                   ^
// [diag.expectedToken] Expected to find ';'.
//                                     ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = if (true) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = l: {} }
//               ^
// [diag.initializedVariableInForEach] The loop variable in a for-each loop can't be initialized.
//                  ^
// [diag.colonInPlaceOfIn] For-in loops use 'in' rather than a colon.
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = int f() {} }
//                     ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                          ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = void f() {} }
//                      ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                             ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = var x; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'var'.
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = return; }
//                 ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                       ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = switch (x) {} }
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = try {} finally {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                                 ^
// [diag.expectedToken] Expected to find ';'.
//                                   ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = while (true) {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; assert (true); }
//                                 ^
// [diag.expectedToken] Expected to find ';'.
//                                   ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; {} }
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; break; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; continue; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; do {} while (true); }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                                      ^
// [diag.expectedToken] Expected to find ';'.
//                                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; for (var x in y) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                                      ^
// [diag.expectedToken] Expected to find ';'.
//                                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; if (true) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; l: {} }
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ':'.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; int f() {} }
//                        ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; void f() {} }
//                         ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                              ^
// [diag.expectedToken] Expected to find ';'.
//                                ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; var x; }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'var'.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; return; }
//                    ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                          ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; switch (x) {} }
//                                ^
// [diag.expectedToken] Expected to find ';'.
//                                  ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; try {} finally {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                                    ^
// [diag.expectedToken] Expected to find ';'.
//                                      ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0; while (true) {} }
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                                  ^
// [diag.expectedToken] Expected to find ';'.
//                                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 assert (true); }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                                ^
// [diag.expectedToken] Expected to find ';'.
//                                  ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 break; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 continue; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                             ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 do {} while (true); }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                                     ^
// [diag.expectedToken] Expected to find ';'.
//                                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 }
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 for (var x in y) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                                     ^
// [diag.expectedToken] Expected to find ';'.
//                                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 if (true) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                              ^
// [diag.expectedToken] Expected to find ';'.
//                                ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 l: {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ':'.
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 int f() {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 void f() {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 var x; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'var'.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 return; }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                         ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 switch (x) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 try {} finally {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                                   ^
// [diag.expectedToken] Expected to find ';'.
//                                     ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0 while (true) {} }
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                   ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                                 ^
// [diag.expectedToken] Expected to find ';'.
//                                   ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for assert (true); }
//        ^^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for {} }
//        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for break; }
//        ^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for continue; }
//        ^^^^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for do {} while (true); }
//        ^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for }
//        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for for (var x in y) {} }
//        ^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for if (true) {} }
//        ^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for l: {} }
//        ^
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
                    name: l
                    colon: :
                statement: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_for_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for int f() {} }
//        ^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for void f() {} }
//        ^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for var x; }
//        ^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for return; }
//        ^^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for switch (x) {} }
//        ^^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for try {} finally {} }
//        ^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for while (true) {} }
//        ^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( assert (true); }
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( break; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( continue; }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( do {} while (true); }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( for (var x in y) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( if (true) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( l: {} }
//           ^
// [diag.colonInPlaceOfIn] For-in loops use 'in' rather than a colon.
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( int f() {} }
//              ^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( void f() {} }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( var x; }
//               ^
// [diag.expectedToken] Expected to find ';'.
//                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( return; }
//          ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//                  ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( switch (x) {} }
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( try {} finally {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                          ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for ( while (true) {} }
//        ^
// [diag.expectedToken] Expected to find ';'.
//          ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) assert (true); }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) break; }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) continue; }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) do {} while (true); }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) }
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.missingIdentifier] Expected an identifier.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) for (var x in y) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) if (true) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) l: {} }
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
                      name: l
                      colon: :
                  statement: Block
                    leftBracket: {
                    rightBracket: }
            rightBracket: }
''');
  }

  void test_for_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) int f() {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) void f() {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) var x; }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) return; }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) switch (x) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) try {} finally {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;;) while (true) {} }
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; assert (true); }
//                                  ^
// [diag.unexpectedToken] Unexpected text ';'.
// [diag.expectedToken] Expected to find ';'.
//                                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; {} }
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; break; }
//                     ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//                          ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; continue; }
//                     ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; do {} while (true); }
//                     ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                                       ^
// [diag.expectedToken] Expected to find ';'.
//                                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; }
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; for (var x in y) {} }
//                     ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                                       ^
// [diag.expectedToken] Expected to find ';'.
//                                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; if (true) {} }
//                     ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                                ^
// [diag.expectedToken] Expected to find ';'.
//                                  ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; l: {} }
//                      ^
// [diag.unexpectedToken] Unexpected text ':'.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; int f() {} }
//                         ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                              ^
// [diag.expectedToken] Expected to find ';'.
//                                ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; void f() {} }
//                          ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; var x; }
//                     ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'var'.
//                          ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; return; }
//                     ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                           ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ';'.
// [diag.expectedToken] Expected to find ';'.
//                             ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; switch (x) {} }
//                                 ^
// [diag.expectedToken] Expected to find ';'.
//                                   ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; try {} finally {} }
//                     ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                                     ^
// [diag.expectedToken] Expected to find ';'.
//                                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i = 0;; while (true) {} }
//                     ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                                   ^
// [diag.expectedToken] Expected to find ';'.
//                                     ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var assert (true); }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
//                          ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var {} }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.missingIdentifier] Expected an identifier.
//              ^
// [diag.expectedToken] Expected to find ';'.
//                ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var break; }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var continue; }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                     ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var do {} while (true); }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text '}'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var for (var x in y) {} }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var if (true) {} }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var l: {} }
//              ^
// [diag.colonInPlaceOfIn] For-in loops use 'in' rather than a colon.
//                 ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var int f() {} }
//         ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//                 ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                        ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var void f() {} }
//         ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var var x; }
//             ^^^
// [diag.duplicatedModifier] The modifier 'var' was already specified.
//                  ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var return; }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'return'.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var switch (x) {} }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^
// [diag.missingIdentifier] Expected an identifier.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var try {} finally {} }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var while (true) {} }
//         ^^^
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                             ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i assert (true); }
//             ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
// [diag.expectedToken] Expected to find ';'.
//                              ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//                ^
// [diag.expectedToken] Expected to find ';'.
//                  ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i break; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'break'.
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i continue; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'continue'.
//                       ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i do {} while (true); }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'do'.
//                                 ^
// [diag.expectedToken] Expected to find ';'.
//                                   ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i for (var x in y) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'for'.
//                                 ^
// [diag.expectedToken] Expected to find ';'.
//                                   ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i if (true) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'if'.
//                          ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i l: {} }
//         ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//                ^
// [diag.colonInPlaceOfIn] For-in loops use 'in' rather than a colon.
//                   ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i int f() {} }
//         ^^^
// [diag.varAndType] Variables can't be declared using both 'var' and a type name.
//               ^^^
// [diag.expectedToken] Expected to find ';'.
//                   ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                          ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i void f() {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                         ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i var x; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'var'.
//                    ^
// [diag.expectedToken] Expected to find ';'.
//                      ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i return; }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                     ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedToken] Expected to find ';'.
//                       ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i switch (x) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                             ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i try {} finally {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'try'.
//                               ^
// [diag.expectedToken] Expected to find ';'.
//                                 ^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { for (var i while (true) {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//               ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text 'while'.
//                             ^
// [diag.expectedToken] Expected to find ';'.
//                               ^
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
