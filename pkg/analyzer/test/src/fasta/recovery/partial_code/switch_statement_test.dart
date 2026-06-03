// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SwitchStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SwitchStatementTest extends ParserDiagnosticsTest {
  void test_switch_statement_expression_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a assert (true); }
//              ^^^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a {} }
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_switch_statement_expression_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a break; }
//              ^^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_expression_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a continue; }
//              ^^^^^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_expression_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a do {} while (true); }
//              ^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a }
//              ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_expression_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a for (var x in y) {} }
//              ^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a if (true) {} }
//              ^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a l: {} }
//              ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a int f() {} }
//              ^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a void f() {} }
//              ^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a var x; }
//              ^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a return; }
//              ^^^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_expression_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a switch (x) {} }
//              ^^^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a try {} finally {} }
//              ^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_expression_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a while (true) {} }
//              ^^^^^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//              ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch assert (true); }
//           ^^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch {} }
//           ^
// [diag.expectedToken] Expected to find '('.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_switch_statement_keyword_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch break; }
//           ^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_keyword_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch continue; }
//           ^^^^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_keyword_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch do {} while (true); }
//           ^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch }
//           ^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_keyword_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch for (var x in y) {} }
//           ^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch if (true) {} }
//           ^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch l: {} }
//           ^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch int f() {} }
//           ^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch void f() {} }
//           ^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch var x; }
//           ^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch return; }
//           ^^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_keyword_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch switch (x) {} }
//           ^^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch try {} finally {} }
//           ^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_keyword_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch while (true) {} }
//           ^^^^^
// [diag.expectedToken] Expected to find '('.
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: ( <synthetic>
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftBrace_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { assert (true); }
//                 ^^^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 36][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { {} }
//                 ^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 24][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { break; }
//                 ^^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 28][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { continue; }
//                 ^^^^^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 31][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { do {} while (true); }
//                 ^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 41][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { }
// [diag.expectedToken][column 21][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { for (var x in y) {} }
//                 ^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 41][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { if (true) {} }
//                 ^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 34][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { l: {} }
//                    ^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 27][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { int f() {} }
//                 ^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 32][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { void f() {} }
//                 ^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 33][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { var x; }
//                 ^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 28][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { return; }
//                 ^^^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 29][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { switch (x) {} }
//                 ^^^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 35][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { try {} finally {} }
//                 ^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 39][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftBrace_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) { while (true) {} }
//                 ^^^^^
// [diag.expectedToken] Expected to find 'case'.
// [diag.expectedToken][column 37][length 1] Expected to find '}'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: } <synthetic>
''');
  }

  void test_switch_statement_leftParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( assert (true); }
//                          ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
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
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              EmptyStatement
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( {} }
//                ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SetOrMapLiteral
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( break; }
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( continue; }
//             ^^^^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( do {} while (true); }
//             ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( }
//             ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( for (var x in y) {} }
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( if (true) {} }
//             ^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( l: {} }
//             ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ';'.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: l
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( int f() {} }
//                 ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                        ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
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
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( void f() {} }
//                  ^
// [diag.namedFunctionExpression] Function expressions can't be named.
//                         ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
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
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( var x; }
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( return; }
//             ^^^^^^
// [diag.unexpectedToken] Unexpected text 'return'.
//                   ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              EmptyStatement
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( switch (x) {} }
//                           ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
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
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_leftParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( try {} finally {} }
//             ^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_leftParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch ( while (true) {} }
//             ^^^^^
// [diag.missingIdentifier] Expected an identifier.
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//             ^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: <empty> <synthetic>
                rightParenthesis: ) <synthetic>
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) assert (true); }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) {} }
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_switch_statement_rightParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) break; }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//               ^^^^^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_rightParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) continue; }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
//               ^^^^^^^^
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_rightParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) do {} while (true); }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_switch_statement_rightParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) for (var x in y) {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) if (true) {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) l: {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) int f() {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) void f() {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) var x; }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) return; }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_switch_statement_rightParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) switch (x) {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) try {} finally {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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

  void test_switch_statement_rightParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { switch (a) while (true) {} }
//             ^
// [diag.expectedSwitchStatementBody] A switch statement must have a body, even if it is empty.
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
              SwitchStatement
                switchKeyword: switch
                leftParenthesis: (
                expression: SimpleIdentifier
                  token: a
                rightParenthesis: )
                leftBracket: { <synthetic>
                rightBracket: } <synthetic>
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
