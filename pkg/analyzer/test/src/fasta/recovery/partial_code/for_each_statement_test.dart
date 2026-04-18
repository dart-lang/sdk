// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForEachStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ForEachStatementTest extends ParserDiagnosticsTest {
  void test_forEach_statement_await_in_assert() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 45, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: FunctionExpressionInvocation
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

  void test_forEach_statement_await_in_block() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
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

  void test_forEach_statement_await_in_break() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 30, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_in_continue() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 30, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_in_do() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 50, 1),
      error(diag.missingIdentifier, 30, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_in_eof() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 30, 1),
      error(diag.expectedToken, 27, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_in_for() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 50, 1),
      error(diag.missingIdentifier, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_in_if() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.missingIdentifier, 30, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_in_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.missingIdentifier, 31, 1),
      error(diag.expectedToken, 30, 1),
      error(diag.unexpectedToken, 31, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_in_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.namedFunctionExpression, 34, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_in_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.namedFunctionExpression, 35, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_in_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_in_return() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.unexpectedToken, 30, 6),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_in_switch() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.missingIdentifier, 44, 1),
      error(diag.expectedToken, 42, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SwitchExpression
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

  void test_forEach_statement_await_in_try() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 48, 1),
      error(diag.missingIdentifier, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_in_while() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 46, 1),
      error(diag.missingIdentifier, 30, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_keyword_assert() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_block() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for {} }
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_break() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 5),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_continue() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 8),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_do() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_eof() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for }
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_keyword_for() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_if() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 2)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for l: {} }
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 4)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_return() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_switch() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 6)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_try() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_keyword_while() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 22, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: ( <synthetic>
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
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

  void test_forEach_statement_await_leftParen_assert() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.invalidAwaitInFor, 12, 5),
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
          keyword: async
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

  void test_forEach_statement_await_leftParen_block() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 24, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_leftParen_break() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_leftParen_continue() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.missingIdentifier, 24, 8),
      error(diag.expectedToken, 24, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_leftParen_do() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.missingIdentifier, 24, 2),
      error(diag.expectedToken, 24, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_leftParen_eof() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.missingIdentifier, 24, 1),
      error(diag.expectedToken, 24, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_leftParen_for() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.missingIdentifier, 24, 3),
      error(diag.expectedToken, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_leftParen_if() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.missingIdentifier, 24, 2),
      error(diag.expectedToken, 24, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_leftParen_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.colonInPlaceOfIn, 25, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
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

  void test_forEach_statement_await_leftParen_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 29, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: int
                    name: f
                  inKeyword: in <synthetic>
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_leftParen_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 30, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: void
                    name: f
                  inKeyword: in <synthetic>
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_leftParen_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.invalidAwaitInFor, 12, 5),
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
          keyword: async
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

  void test_forEach_statement_await_leftParen_return() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.unexpectedToken, 24, 6),
      error(diag.missingIdentifier, 30, 1),
      error(diag.invalidAwaitInFor, 12, 5),
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
          keyword: async
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

  void test_forEach_statement_await_leftParen_switch() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedToken, 38, 1),
      error(diag.missingIdentifier, 24, 6),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_leftParen_try() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.missingIdentifier, 24, 3),
      error(diag.expectedToken, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_leftParen_while() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 24, 5),
      error(diag.expectedToken, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: <empty> <synthetic>
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_stream_assert() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 47, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_block() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b {} }
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_forEach_statement_await_stream_break() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b break; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 39, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_stream_continue() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b continue; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 42, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_stream_do() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 52, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_eof() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_stream_for() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 52, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_if() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 45, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 38, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
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

  void test_forEach_statement_await_stream_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 43, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 44, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 39, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_return() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 40, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_stream_switch() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 46, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_try() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 50, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_stream_while() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a in b while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 48, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_await_typeAndVariableName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.expectedToken, 27, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: FunctionExpressionInvocation
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

  void test_forEach_statement_await_typeAndVariableName_block() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedToken, 27, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
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

  void test_forEach_statement_await_typeAndVariableName_break() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 27, 5),
      error(diag.missingIdentifier, 27, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_typeAndVariableName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 27, 8),
      error(diag.missingIdentifier, 27, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_typeAndVariableName_do() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 47, 1),
      error(diag.expectedToken, 27, 2),
      error(diag.missingIdentifier, 27, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_typeAndVariableName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a }
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_typeAndVariableName_for() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 47, 1),
      error(diag.expectedToken, 27, 3),
      error(diag.missingIdentifier, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_typeAndVariableName_if() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.expectedToken, 27, 2),
      error(diag.missingIdentifier, 27, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_typeAndVariableName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 28, 1),
      error(diag.expectedToken, 27, 1),
      error(diag.unexpectedToken, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_typeAndVariableName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedToken, 27, 3),
      error(diag.namedFunctionExpression, 31, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_typeAndVariableName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedToken, 27, 4),
      error(diag.namedFunctionExpression, 32, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_typeAndVariableName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 27, 3),
      error(diag.missingIdentifier, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_typeAndVariableName_return() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 27, 6),
      error(diag.unexpectedToken, 27, 6),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_typeAndVariableName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 27, 6),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SwitchExpression
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

  void test_forEach_statement_await_typeAndVariableName_try() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.expectedToken, 27, 3),
      error(diag.missingIdentifier, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_typeAndVariableName_while() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (A a while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.expectedToken, 27, 5),
      error(diag.missingIdentifier, 27, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: A
                    name: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_variableName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.expectedToken, 25, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: FunctionExpressionInvocation
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

  void test_forEach_statement_await_variableName_block() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 25, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
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

  void test_forEach_statement_await_variableName_break() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 25, 5),
      error(diag.missingIdentifier, 25, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_variableName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 25, 8),
      error(diag.missingIdentifier, 25, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_variableName_do() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.expectedToken, 25, 2),
      error(diag.missingIdentifier, 25, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_variableName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a }
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_await_variableName_for() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.expectedToken, 25, 3),
      error(diag.missingIdentifier, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_variableName_if() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.expectedToken, 25, 2),
      error(diag.missingIdentifier, 25, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_variableName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.colonInPlaceOfIn, 26, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: a
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

  void test_forEach_statement_await_variableName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 29, 1),
      error(diag.namedFunctionExpression, 29, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    type: NamedType
                      name: a
                    name: int
                  inKeyword: in <synthetic>
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_variableName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 25, 4),
      error(diag.namedFunctionExpression, 30, 1),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: FunctionExpression
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

  void test_forEach_statement_await_variableName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 25, 3),
      error(diag.missingIdentifier, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_variableName_return() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 25, 6),
      error(diag.unexpectedToken, 25, 6),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_await_variableName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedToken, 25, 6),
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
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SwitchExpression
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

  void test_forEach_statement_await_variableName_try() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.expectedToken, 25, 3),
      error(diag.missingIdentifier, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_await_variableName_while() {
    var parseResult = parseStringWithErrors(r'''
f() async { await for (a while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 25, 5),
      error(diag.missingIdentifier, 25, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          keyword: async
          block: Block
            leftBracket: {
            statements
              ForStatement
                awaitKeyword: await
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithIdentifier
                  identifier: SimpleIdentifier
                    token: a
                  inKeyword: in <synthetic>
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in assert (true); }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: FunctionExpressionInvocation
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

  void test_forEach_statement_in_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in {} }
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
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
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

  void test_forEach_statement_in_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 20, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_in_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.missingIdentifier, 20, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_in_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 20, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 20, 1),
      error(diag.missingIdentifier, 20, 1),
      error(diag.expectedToken, 17, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_in_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.missingIdentifier, 20, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 20, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedToken, 20, 1),
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.namedFunctionExpression, 24, 1),
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
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: FunctionExpression
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

  void test_forEach_statement_in_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.namedFunctionExpression, 25, 1),
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
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: FunctionExpression
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

  void test_forEach_statement_in_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.missingIdentifier, 20, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in return; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_in_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in switch (x) {} }
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
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SwitchExpression
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

  void test_forEach_statement_in_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.missingIdentifier, 20, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_in_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.missingIdentifier, 20, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
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

  void test_forEach_statement_iterator_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 37, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_block() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_forEach_statement_iterator_break() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b break; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: BreakStatement
                  breakKeyword: break
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_iterator_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b continue; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: ContinueStatement
                  continueKeyword: continue
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_iterator_do() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 42, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b }
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
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: ExpressionStatement
                  expression: SimpleIdentifier
                    token: <empty> <synthetic>
                  semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_forEach_statement_iterator_for() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 42, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_if() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b if (true) {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b l: {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
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

  void test_forEach_statement_iterator_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b int f() {} }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 34, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b var x; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_return() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b return; }
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
              ForStatement
                forKeyword: for
                leftParenthesis: (
                forLoopParts: ForEachPartsWithDeclaration
                  loopVariable: DeclaredIdentifier
                    keyword: var
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
                rightParenthesis: ) <synthetic>
                body: ReturnStatement
                  returnKeyword: return
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_forEach_statement_iterator_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 36, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_try() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 40, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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

  void test_forEach_statement_iterator_while() {
    var parseResult = parseStringWithErrors(r'''
f() { for (var a in b while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 38, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
                    name: a
                  inKeyword: in
                  iterable: SimpleIdentifier
                    token: b
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
