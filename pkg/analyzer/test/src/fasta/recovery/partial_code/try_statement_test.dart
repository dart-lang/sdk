// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TryStatementTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TryStatementTest extends ParserDiagnosticsTest {
  void test_try_statement_catch_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch assert (true); }
//                 ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch {} }
//                 ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_catch_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch break; }
//                 ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch continue; }
//                 ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch do {} while (true); }
//                 ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch }
//                 ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch for (var x in y) {} }
//                 ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e assert (true); }
//                    ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e {} }
//                    ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifier_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e break; }
//                    ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifier_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e continue; }
//                    ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifier_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e do {} while (true); }
//                    ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e }
//                    ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifier_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e for (var x in y) {} }
//                    ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e if (true) {} }
//                    ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e l: {} }
//                    ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e int f() {} }
//                    ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e void f() {} }
//                    ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e var x; }
//                    ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e return; }
//                    ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifier_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e switch (x) {} }
//                    ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e try {} finally {} }
//                    ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifier_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e while (true) {} }
//                    ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                    ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  assert (true); }
//                      ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  {} }
//                      ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
//                       ^
// [diag.expectedToken] Expected to find '}'.
//                         ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierComma_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  break; }
//                      ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierComma_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  continue; }
//                      ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierComma_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  do {} while (true); }
//                      ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  }
//                      ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierComma_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  for (var x in y) {} }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  if (true) {} }
//                      ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  l: {} }
//                      ^
// [diag.expectedToken] Expected to find ';'.
//                       ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: l
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  int f() {} }
//                          ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: int
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
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

  void test_try_statement_catch_identifierComma_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  void f() {} }
//                      ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  var x; }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  return; }
//                      ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierComma_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  switch (x) {} }
//                      ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  try {} finally {} }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierComma_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e,  while (true) {} }
//                      ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                      ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s assert (true); }
//                       ^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s {} }
//                       ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierCommaIdentifier_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s break; }
//                       ^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierCommaIdentifier_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s continue; }
//                       ^^^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierCommaIdentifier_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s do {} while (true); }
//                       ^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s }
//                       ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierCommaIdentifier_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s for (var x in y) {} }
//                       ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s if (true) {} }
//                       ^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s l: {} }
//                       ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void
  test_try_statement_catch_identifierCommaIdentifier_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s int f() {} }
//                       ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s void f() {} }
//                       ^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s var x; }
//                       ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s return; }
//                       ^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_identifierCommaIdentifier_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s switch (x) {} }
//                       ^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s try {} finally {} }
//                       ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_identifierCommaIdentifier_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s while (true) {} }
//                       ^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                       ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch if (true) {} }
//                 ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch l: {} }
//                 ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( assert (true); }
//                   ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( {} }
//                   ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
//                    ^
// [diag.expectedToken] Expected to find '}'.
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_leftParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( break; }
//                   ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_leftParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( continue; }
//                   ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_leftParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( do {} while (true); }
//                   ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( }
//                   ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_leftParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( for (var x in y) {} }
//                   ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( if (true) {} }
//                   ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( l: {} }
//                   ^
// [diag.expectedToken] Expected to find ';'.
//                    ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: l
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( int f() {} }
//                       ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: int
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
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

  void test_try_statement_catch_leftParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( void f() {} }
//                   ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( var x; }
//                   ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( return; }
//                   ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_leftParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( switch (x) {} }
//                   ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( try {} finally {} }
//                   ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_leftParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch ( while (true) {} }
//                   ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                   ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch int f() {} }
//                 ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch void f() {} }
//                 ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch var x; }
//                 ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch return; }
//                 ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_rightParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) assert (true); }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) {} }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_catch_rightParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) break; }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_rightParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) continue; }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_rightParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) do {} while (true); }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_catch_rightParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) for (var x in y) {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) if (true) {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) l: {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) int f() {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) void f() {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) var x; }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) return; }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_catch_rightParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) switch (x) {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) try {} finally {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_rightParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e, s) while (true) {} }
//                      ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_catch_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch switch (x) {} }
//                 ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch try {} finally {} }
//                 ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_catch_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch while (true) {} }
//                 ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_finally_catch_noBlock_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally assert (true); }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally {} }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
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

  void test_try_statement_finally_catch_noBlock_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally break; }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
//                                ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_finally_catch_noBlock_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally continue; }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
//                                ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_finally_catch_noBlock_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally do {} while (true); }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_finally_catch_noBlock_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally for (var x in y) {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally if (true) {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally l: {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally int f() {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally void f() {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally var x; }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally return; }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_finally_catch_noBlock_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally switch (x) {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally try {} finally {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_catch_noBlock_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} catch (e) {} finally while (true) {} }
//                        ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally assert (true); }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally {} }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_try_statement_finally_noCatch_noBlock_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally break; }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
//                   ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_finally_noCatch_noBlock_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally continue; }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
//                   ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_finally_noCatch_noBlock_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally do {} while (true); }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_finally_noCatch_noBlock_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally for (var x in y) {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally if (true) {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally l: {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally int f() {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally void f() {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally var x; }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally return; }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_finally_noCatch_noBlock_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally switch (x) {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally try {} finally {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_finally_noCatch_noBlock_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} finally while (true) {} }
//           ^^^^^^^
// [diag.expectedFinallyClauseBody] A finally clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                finallyKeyword: finally
                finallyBlock: Block
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

  void test_try_statement_keyword_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try assert (true); }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_keyword_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try break; }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
//        ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_keyword_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try continue; }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
//        ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_keyword_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try do {} while (true); }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_keyword_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try for (var x in y) {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try if (true) {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try l: {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try int f() {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try void f() {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try var x; }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try return; }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: { <synthetic>
                  rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_keyword_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try switch (x) {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try try {} finally {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_keyword_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try while (true) {} }
//    ^^^
// [diag.expectedTryStatementBody] A try statement must have a body, even if it is empty.
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
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

  void test_try_statement_noCatchOrFinally_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} assert (true); }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_noCatchOrFinally_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} break; }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
//           ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_noCatchOrFinally_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} continue; }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
//           ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_noCatchOrFinally_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} do {} while (true); }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_noCatchOrFinally_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} for (var x in y) {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} if (true) {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} l: {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} int f() {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} void f() {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} var x; }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} return; }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_noCatchOrFinally_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} switch (x) {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} try {} finally {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_noCatchOrFinally_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} while (true) {} }
//    ^^^
// [diag.missingCatchOrFinally] A try block must be followed by an 'on', 'catch', or 'finally' clause.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
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

  void test_try_statement_on_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on assert (true); }
//              ^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on {} }
//              ^
// [diag.expectedTypeName] Expected a type name.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_on_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on break; }
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch assert (true); }
//                      ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch {} }
//                      ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch break; }
//                      ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch continue; }
//                      ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch do {} while (true); }
//                      ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch }
//                      ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch for (var x in y) {} }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e assert (true); }
//                         ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e {} }
//                         ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifier_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e break; }
//                         ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifier_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e continue; }
//                         ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifier_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e do {} while (true); }
//                         ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e }
//                         ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifier_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e for (var x in y) {} }
//                         ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e if (true) {} }
//                         ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e l: {} }
//                         ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e int f() {} }
//                         ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e void f() {} }
//                         ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e var x; }
//                         ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e return; }
//                         ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifier_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e switch (x) {} }
//                         ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e try {} finally {} }
//                         ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifier_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e while (true) {} }
//                         ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                         ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  assert (true); }
//                           ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  {} }
//                           ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
//                            ^
// [diag.expectedToken] Expected to find '}'.
//                              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierComma_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  break; }
//                           ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierComma_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  continue; }
//                           ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierComma_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  do {} while (true); }
//                           ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  }
//                           ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierComma_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  for (var x in y) {} }
//                           ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  if (true) {} }
//                           ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  l: {} }
//                           ^
// [diag.expectedToken] Expected to find ';'.
//                            ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: l
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  int f() {} }
//                               ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: int
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
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

  void test_try_statement_on_catch_identifierComma_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  void f() {} }
//                           ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  var x; }
//                           ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  return; }
//                           ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierComma_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  switch (x) {} }
//                           ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  try {} finally {} }
//                           ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierComma_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e,  while (true) {} }
//                           ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                           ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s assert (true); }
//                            ^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s {} }
//                            ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierCommaIdentifier_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s break; }
//                            ^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierCommaIdentifier_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s continue; }
//                            ^^^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierCommaIdentifier_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s do {} while (true); }
//                            ^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s }
//                            ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierCommaIdentifier_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s for (var x in y) {} }
//                            ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s if (true) {} }
//                            ^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s l: {} }
//                            ^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void
  test_try_statement_on_catch_identifierCommaIdentifier_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s int f() {} }
//                            ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void
  test_try_statement_on_catch_identifierCommaIdentifier_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s void f() {} }
//                            ^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s var x; }
//                            ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s return; }
//                            ^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_identifierCommaIdentifier_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s switch (x) {} }
//                            ^^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s try {} finally {} }
//                            ^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_identifierCommaIdentifier_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s while (true) {} }
//                            ^^^^^
// [diag.catchSyntaxExtraParameters] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                            ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch if (true) {} }
//                      ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch l: {} }
//                      ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( assert (true); }
//                        ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( {} }
//                        ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
//                         ^
// [diag.expectedToken] Expected to find '}'.
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_leftParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( break; }
//                        ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.breakOutsideOfLoop] A break statement can't be used outside of a loop or switch statement.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_leftParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( continue; }
//                        ^^^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.continueOutsideOfLoop] A continue statement can't be used outside of a loop or switch statement.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_leftParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( do {} while (true); }
//                        ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( }
//                        ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_leftParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( for (var x in y) {} }
//                        ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( if (true) {} }
//                        ^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( l: {} }
//                        ^
// [diag.expectedToken] Expected to find ';'.
//                         ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: l
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( int f() {} }
//                            ^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: int
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
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

  void test_try_statement_on_catch_leftParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( void f() {} }
//                        ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( var x; }
//                        ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( return; }
//                        ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_leftParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( switch (x) {} }
//                        ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( try {} finally {} }
//                        ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_leftParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch ( while (true) {} }
//                        ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                        ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch int f() {} }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch void f() {} }
//                      ^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch var x; }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch return; }
//                      ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_rightParen_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) assert (true); }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) {} }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_rightParen_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) break; }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                             ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_rightParen_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) continue; }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                             ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_rightParen_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) do {} while (true); }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_rightParen_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) for (var x in y) {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) if (true) {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) l: {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) int f() {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) void f() {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) var x; }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) return; }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_catch_rightParen_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) switch (x) {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) try {} finally {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_rightParen_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch (e, s) while (true) {} }
//                           ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: (
                    exceptionParameter: CatchClauseParameter
                      name: e
                    comma: ,
                    stackTraceParameter: CatchClauseParameter
                      name: s
                    rightParenthesis: )
                    body: Block
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

  void test_try_statement_on_catch_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch switch (x) {} }
//                      ^^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch try {} finally {} }
//                      ^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_catch_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A catch while (true) {} }
//                      ^^^^^
// [diag.catchSyntax] 'catch' must be followed by '(identifier)' or '(identifier, identifier)'.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    catchKeyword: catch
                    leftParenthesis: ( <synthetic>
                    exceptionParameter: CatchClauseParameter
                      name: <empty> <synthetic>
                    rightParenthesis: ) <synthetic>
                    body: Block
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

  void test_try_statement_on_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on continue; }
//              ^^^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on do {} while (true); }
//              ^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on }
//              ^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on for (var x in y) {} }
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_identifier_assert() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A assert (true); }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_block() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A {} }
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
                      leftBracket: {
                      rightBracket: }
            rightBracket: }
''');
  }

  void test_try_statement_on_identifier_break() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A break; }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                ^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_identifier_continue() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A continue; }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
//                ^^^^^^^^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_identifier_do() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A do {} while (true); }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_eof() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
            rightBracket: }
''');
  }

  void test_try_statement_on_identifier_for() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A for (var x in y) {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A if (true) {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A l: {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A int f() {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A void f() {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A var x; }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A return; }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_identifier_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A switch (x) {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A try {} finally {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_identifier_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on A while (true) {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: A
                    body: Block
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

  void test_try_statement_on_if() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on if (true) {} }
//              ^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_labeled() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on l: {} }
//              ^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
// [diag.expectedToken] Expected to find ';'.
//               ^
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
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: l
                    body: Block
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

  void test_try_statement_on_localFunctionNonVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on int f() {} }
//              ^^^
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: int
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
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

  void test_try_statement_on_localFunctionVoid() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on void f() {} }
//              ^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: void
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
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

  void test_try_statement_on_localVariable() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on var x; }
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_return() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on return; }
//              ^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
                      leftBracket: { <synthetic>
                      rightBracket: } <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_try_statement_on_switch() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on switch (x) {} }
//              ^^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_try() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on try {} finally {} }
//              ^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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

  void test_try_statement_on_while() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
f() { try {} on while (true) {} }
//              ^^^^^
// [diag.expectedTypeName] Expected a type name.
// [diag.expectedCatchClauseBody] A catch clause must have a body, even if it is empty.
''');
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              TryStatement
                tryKeyword: try
                body: Block
                  leftBracket: {
                  rightBracket: }
                catchClauses
                  CatchClause
                    onKeyword: on
                    exceptionType: NamedType
                      name: <empty> <synthetic>
                    body: Block
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
