// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue assert (true); }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue break; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue continue; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
//             ^^^^^^^^
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue do {} while (true); }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
              ContinueStatement
                continueKeyword: continue
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_continue_statement_keyword_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue for (var x in y) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue if (true) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue l: {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
//              ^
// [diag.missingIdentifier] Expected an identifier.
// [diag.unexpectedToken] Unexpected text ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue int f() {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^^^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue void f() {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue var x; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue return; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue switch (x) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue try {} finally {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue while (true) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a assert (true); }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a break; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a continue; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a do {} while (true); }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
              ContinueStatement
                continueKeyword: continue
                label: LabelReference
                  name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_continue_statement_label_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a for (var x in y) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a if (true) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a l: {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a int f() {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a void f() {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a var x; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a return; }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a switch (x) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a try {} finally {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { continue a while (true) {} }
//    ^^^^^^^^
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//             ^
// [diag.expectedToken] Expected to find ';'.
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
