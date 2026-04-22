// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch assert (true); }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 6),
      error(diag.expectedCatchClauseBody, 19, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch {} }
''');
    parseResult.assertErrors([error(diag.catchSyntax, 19, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch break; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 5),
      error(diag.expectedCatchClauseBody, 19, 5),
      error(diag.breakOutsideOfLoop, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch continue; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 8),
      error(diag.expectedCatchClauseBody, 19, 8),
      error(diag.continueOutsideOfLoop, 19, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 2),
      error(diag.expectedCatchClauseBody, 19, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 1),
      error(diag.expectedCatchClauseBody, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 3),
      error(diag.expectedCatchClauseBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntax, 22, 6),
      error(diag.expectedCatchClauseBody, 22, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.catchSyntax, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.catchSyntax, 22, 5),
      error(diag.expectedCatchClauseBody, 22, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntax, 22, 8),
      error(diag.expectedCatchClauseBody, 22, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntax, 22, 2),
      error(diag.expectedCatchClauseBody, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedCatchClauseBody, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntax, 22, 3),
      error(diag.expectedCatchClauseBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.catchSyntax, 22, 2),
      error(diag.expectedCatchClauseBody, 22, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.catchSyntax, 22, 1),
      error(diag.expectedCatchClauseBody, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntax, 22, 3),
      error(diag.expectedCatchClauseBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.catchSyntax, 22, 4),
      error(diag.expectedCatchClauseBody, 22, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.catchSyntax, 22, 3),
      error(diag.expectedCatchClauseBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.catchSyntax, 22, 6),
      error(diag.expectedCatchClauseBody, 22, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntax, 22, 6),
      error(diag.expectedCatchClauseBody, 22, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntax, 22, 3),
      error(diag.expectedCatchClauseBody, 22, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.catchSyntax, 22, 5),
      error(diag.expectedCatchClauseBody, 22, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.catchSyntax, 24, 6),
      error(diag.expectedCatchClauseBody, 24, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.catchSyntax, 24, 1),
      error(diag.expectedToken, 25, 1),
      error(diag.expectedCatchClauseBody, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.catchSyntax, 24, 5),
      error(diag.expectedCatchClauseBody, 24, 5),
      error(diag.breakOutsideOfLoop, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.catchSyntax, 24, 8),
      error(diag.expectedCatchClauseBody, 24, 8),
      error(diag.continueOutsideOfLoop, 24, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.catchSyntax, 24, 2),
      error(diag.expectedCatchClauseBody, 24, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.catchSyntax, 24, 1),
      error(diag.expectedCatchClauseBody, 24, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntax, 24, 2),
      error(diag.expectedCatchClauseBody, 24, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.catchSyntaxExtraParameters, 25, 1),
      error(diag.expectedCatchClauseBody, 25, 1),
      error(diag.missingIdentifier, 25, 1),
      error(diag.expectedToken, 24, 1),
      error(diag.unexpectedToken, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.catchSyntaxExtraParameters, 28, 1),
      error(diag.expectedCatchClauseBody, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntax, 24, 4),
      error(diag.expectedCatchClauseBody, 24, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntax, 24, 6),
      error(diag.expectedCatchClauseBody, 24, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.catchSyntax, 24, 6),
      error(diag.expectedCatchClauseBody, 24, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e,  while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntax, 24, 5),
      error(diag.expectedCatchClauseBody, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntaxExtraParameters, 25, 6),
      error(diag.expectedCatchClauseBody, 25, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.catchSyntaxExtraParameters, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntaxExtraParameters, 25, 5),
      error(diag.expectedCatchClauseBody, 25, 5),
      error(diag.breakOutsideOfLoop, 25, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.catchSyntaxExtraParameters, 25, 8),
      error(diag.expectedCatchClauseBody, 25, 8),
      error(diag.continueOutsideOfLoop, 25, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.catchSyntaxExtraParameters, 25, 2),
      error(diag.expectedCatchClauseBody, 25, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.expectedCatchClauseBody, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.catchSyntaxExtraParameters, 25, 3),
      error(diag.expectedCatchClauseBody, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.catchSyntaxExtraParameters, 25, 2),
      error(diag.expectedCatchClauseBody, 25, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.catchSyntaxExtraParameters, 25, 1),
      error(diag.expectedCatchClauseBody, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntaxExtraParameters, 25, 3),
      error(diag.expectedCatchClauseBody, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntaxExtraParameters, 25, 4),
      error(diag.expectedCatchClauseBody, 25, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntaxExtraParameters, 25, 3),
      error(diag.expectedCatchClauseBody, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntaxExtraParameters, 25, 6),
      error(diag.expectedCatchClauseBody, 25, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.catchSyntaxExtraParameters, 25, 6),
      error(diag.expectedCatchClauseBody, 25, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.catchSyntaxExtraParameters, 25, 3),
      error(diag.expectedCatchClauseBody, 25, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntaxExtraParameters, 25, 5),
      error(diag.expectedCatchClauseBody, 25, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 2),
      error(diag.expectedCatchClauseBody, 19, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch l: {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 1),
      error(diag.expectedCatchClauseBody, 19, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntax, 21, 6),
      error(diag.expectedCatchClauseBody, 21, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.catchSyntax, 21, 1),
      error(diag.expectedToken, 22, 1),
      error(diag.expectedCatchClauseBody, 24, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.catchSyntax, 21, 5),
      error(diag.expectedCatchClauseBody, 21, 5),
      error(diag.breakOutsideOfLoop, 21, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.catchSyntax, 21, 8),
      error(diag.expectedCatchClauseBody, 21, 8),
      error(diag.continueOutsideOfLoop, 21, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntax, 21, 2),
      error(diag.expectedCatchClauseBody, 21, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.catchSyntax, 21, 1),
      error(diag.expectedCatchClauseBody, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntax, 21, 3),
      error(diag.expectedCatchClauseBody, 21, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.catchSyntax, 21, 2),
      error(diag.expectedCatchClauseBody, 21, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.catchSyntax, 22, 1),
      error(diag.expectedCatchClauseBody, 22, 1),
      error(diag.missingIdentifier, 22, 1),
      error(diag.expectedToken, 21, 1),
      error(diag.unexpectedToken, 22, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntax, 25, 1),
      error(diag.expectedCatchClauseBody, 25, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntax, 21, 4),
      error(diag.expectedCatchClauseBody, 21, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.catchSyntax, 21, 3),
      error(diag.expectedCatchClauseBody, 21, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.catchSyntax, 21, 6),
      error(diag.expectedCatchClauseBody, 21, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.catchSyntax, 21, 6),
      error(diag.expectedCatchClauseBody, 21, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.catchSyntax, 21, 3),
      error(diag.expectedCatchClauseBody, 21, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntax, 21, 5),
      error(diag.expectedCatchClauseBody, 21, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch int f() {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 3),
      error(diag.expectedCatchClauseBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch void f() {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 4),
      error(diag.expectedCatchClauseBody, 19, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch var x; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 3),
      error(diag.expectedCatchClauseBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch return; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 6),
      error(diag.expectedCatchClauseBody, 19, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) break; }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 24, 1),
      error(diag.breakOutsideOfLoop, 26, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 24, 1),
      error(diag.continueOutsideOfLoop, 26, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) l: {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) var x; }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) return; }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e, s) while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 6),
      error(diag.expectedCatchClauseBody, 19, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 3),
      error(diag.expectedCatchClauseBody, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 19, 5),
      error(diag.expectedCatchClauseBody, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally break; }
''');
    parseResult.assertErrors([
      error(diag.expectedFinallyClauseBody, 26, 7),
      error(diag.breakOutsideOfLoop, 34, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedFinallyClauseBody, 26, 7),
      error(diag.continueOutsideOfLoop, 34, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally l: {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally var x; }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally return; }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} catch (e) {} finally while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 26, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally break; }
''');
    parseResult.assertErrors([
      error(diag.expectedFinallyClauseBody, 13, 7),
      error(diag.breakOutsideOfLoop, 21, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedFinallyClauseBody, 13, 7),
      error(diag.continueOutsideOfLoop, 21, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally l: {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally var x; }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally return; }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} finally while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedFinallyClauseBody, 13, 7)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try break; }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { try continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
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
    var parseResult = parseStringWithErrors(r'''
f() { try do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try return; }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTryStatementBody, 6, 3),
      error(diag.missingCatchOrFinally, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} assert (true); }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} break; }
''');
    parseResult.assertErrors([
      error(diag.missingCatchOrFinally, 6, 3),
      error(diag.breakOutsideOfLoop, 13, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} continue; }
''');
    parseResult.assertErrors([
      error(diag.missingCatchOrFinally, 6, 3),
      error(diag.continueOutsideOfLoop, 13, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} do {} while (true); }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} if (true) {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} l: {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} int f() {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} void f() {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} var x; }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} return; }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} switch (x) {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} try {} finally {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} while (true) {} }
''');
    parseResult.assertErrors([error(diag.missingCatchOrFinally, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 6),
      error(diag.expectedCatchClauseBody, 16, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on {} }
''');
    parseResult.assertErrors([error(diag.expectedTypeName, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on break; }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedCatchClauseBody, 16, 5),
      error(diag.breakOutsideOfLoop, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch assert (true); }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 6),
      error(diag.expectedCatchClauseBody, 24, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch {} }
''');
    parseResult.assertErrors([error(diag.catchSyntax, 24, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch break; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 5),
      error(diag.expectedCatchClauseBody, 24, 5),
      error(diag.breakOutsideOfLoop, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch continue; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 8),
      error(diag.expectedCatchClauseBody, 24, 8),
      error(diag.continueOutsideOfLoop, 24, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 2),
      error(diag.expectedCatchClauseBody, 24, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 1),
      error(diag.expectedCatchClauseBody, 24, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntax, 27, 6),
      error(diag.expectedCatchClauseBody, 27, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.catchSyntax, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.catchSyntax, 27, 5),
      error(diag.expectedCatchClauseBody, 27, 5),
      error(diag.breakOutsideOfLoop, 27, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntax, 27, 8),
      error(diag.expectedCatchClauseBody, 27, 8),
      error(diag.continueOutsideOfLoop, 27, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 47, 1),
      error(diag.catchSyntax, 27, 2),
      error(diag.expectedCatchClauseBody, 27, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedCatchClauseBody, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 47, 1),
      error(diag.catchSyntax, 27, 3),
      error(diag.expectedCatchClauseBody, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntax, 27, 2),
      error(diag.expectedCatchClauseBody, 27, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntax, 27, 1),
      error(diag.expectedCatchClauseBody, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.catchSyntax, 27, 3),
      error(diag.expectedCatchClauseBody, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.catchSyntax, 27, 4),
      error(diag.expectedCatchClauseBody, 27, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.catchSyntax, 27, 3),
      error(diag.expectedCatchClauseBody, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.catchSyntax, 27, 6),
      error(diag.expectedCatchClauseBody, 27, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntax, 27, 6),
      error(diag.expectedCatchClauseBody, 27, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.catchSyntax, 27, 3),
      error(diag.expectedCatchClauseBody, 27, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.catchSyntax, 27, 5),
      error(diag.expectedCatchClauseBody, 27, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.catchSyntax, 29, 6),
      error(diag.expectedCatchClauseBody, 29, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntax, 29, 1),
      error(diag.expectedToken, 30, 1),
      error(diag.expectedCatchClauseBody, 32, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntax, 29, 5),
      error(diag.expectedCatchClauseBody, 29, 5),
      error(diag.breakOutsideOfLoop, 29, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.catchSyntax, 29, 8),
      error(diag.expectedCatchClauseBody, 29, 8),
      error(diag.continueOutsideOfLoop, 29, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 49, 1),
      error(diag.catchSyntax, 29, 2),
      error(diag.expectedCatchClauseBody, 29, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.catchSyntax, 29, 1),
      error(diag.expectedCatchClauseBody, 29, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 49, 1),
      error(diag.catchSyntax, 29, 3),
      error(diag.expectedCatchClauseBody, 29, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntax, 29, 2),
      error(diag.expectedCatchClauseBody, 29, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.catchSyntaxExtraParameters, 30, 1),
      error(diag.expectedCatchClauseBody, 30, 1),
      error(diag.missingIdentifier, 30, 1),
      error(diag.expectedToken, 29, 1),
      error(diag.unexpectedToken, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntaxExtraParameters, 33, 1),
      error(diag.expectedCatchClauseBody, 33, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntax, 29, 4),
      error(diag.expectedCatchClauseBody, 29, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntax, 29, 3),
      error(diag.expectedCatchClauseBody, 29, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntax, 29, 6),
      error(diag.expectedCatchClauseBody, 29, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.catchSyntax, 29, 6),
      error(diag.expectedCatchClauseBody, 29, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 47, 1),
      error(diag.catchSyntax, 29, 3),
      error(diag.expectedCatchClauseBody, 29, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e,  while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.catchSyntax, 29, 5),
      error(diag.expectedCatchClauseBody, 29, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 45, 1),
      error(diag.catchSyntaxExtraParameters, 30, 6),
      error(diag.expectedCatchClauseBody, 30, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntaxExtraParameters, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntaxExtraParameters, 30, 5),
      error(diag.expectedCatchClauseBody, 30, 5),
      error(diag.breakOutsideOfLoop, 30, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntaxExtraParameters, 30, 8),
      error(diag.expectedCatchClauseBody, 30, 8),
      error(diag.continueOutsideOfLoop, 30, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 50, 1),
      error(diag.catchSyntaxExtraParameters, 30, 2),
      error(diag.expectedCatchClauseBody, 30, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedCatchClauseBody, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 50, 1),
      error(diag.catchSyntaxExtraParameters, 30, 3),
      error(diag.expectedCatchClauseBody, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 43, 1),
      error(diag.catchSyntaxExtraParameters, 30, 2),
      error(diag.expectedCatchClauseBody, 30, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntaxExtraParameters, 30, 1),
      error(diag.expectedCatchClauseBody, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntaxExtraParameters, 30, 3),
      error(diag.expectedCatchClauseBody, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntaxExtraParameters, 30, 4),
      error(diag.expectedCatchClauseBody, 30, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntaxExtraParameters, 30, 3),
      error(diag.expectedCatchClauseBody, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.catchSyntaxExtraParameters, 30, 6),
      error(diag.expectedCatchClauseBody, 30, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.catchSyntaxExtraParameters, 30, 6),
      error(diag.expectedCatchClauseBody, 30, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 48, 1),
      error(diag.catchSyntaxExtraParameters, 30, 3),
      error(diag.expectedCatchClauseBody, 30, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 46, 1),
      error(diag.catchSyntaxExtraParameters, 30, 5),
      error(diag.expectedCatchClauseBody, 30, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 2),
      error(diag.expectedCatchClauseBody, 24, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch l: {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 1),
      error(diag.expectedCatchClauseBody, 24, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.catchSyntax, 26, 6),
      error(diag.expectedCatchClauseBody, 26, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.catchSyntax, 26, 1),
      error(diag.expectedToken, 27, 1),
      error(diag.expectedCatchClauseBody, 29, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntax, 26, 5),
      error(diag.expectedCatchClauseBody, 26, 5),
      error(diag.breakOutsideOfLoop, 26, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.catchSyntax, 26, 8),
      error(diag.expectedCatchClauseBody, 26, 8),
      error(diag.continueOutsideOfLoop, 26, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 46, 1),
      error(diag.catchSyntax, 26, 2),
      error(diag.expectedCatchClauseBody, 26, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.catchSyntax, 26, 1),
      error(diag.expectedCatchClauseBody, 26, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 46, 1),
      error(diag.catchSyntax, 26, 3),
      error(diag.expectedCatchClauseBody, 26, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.catchSyntax, 26, 2),
      error(diag.expectedCatchClauseBody, 26, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.catchSyntax, 27, 1),
      error(diag.expectedCatchClauseBody, 27, 1),
      error(diag.missingIdentifier, 27, 1),
      error(diag.expectedToken, 26, 1),
      error(diag.unexpectedToken, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.catchSyntax, 30, 1),
      error(diag.expectedCatchClauseBody, 30, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 38, 1),
      error(diag.catchSyntax, 26, 4),
      error(diag.expectedCatchClauseBody, 26, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.catchSyntax, 26, 3),
      error(diag.expectedCatchClauseBody, 26, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.catchSyntax, 26, 6),
      error(diag.expectedCatchClauseBody, 26, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 40, 1),
      error(diag.catchSyntax, 26, 6),
      error(diag.expectedCatchClauseBody, 26, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 44, 1),
      error(diag.catchSyntax, 26, 3),
      error(diag.expectedCatchClauseBody, 26, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 42, 1),
      error(diag.catchSyntax, 26, 5),
      error(diag.expectedCatchClauseBody, 26, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch int f() {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch void f() {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 4),
      error(diag.expectedCatchClauseBody, 24, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch var x; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch return; }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 6),
      error(diag.expectedCatchClauseBody, 24, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) break; }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 29, 1),
      error(diag.breakOutsideOfLoop, 31, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 29, 1),
      error(diag.continueOutsideOfLoop, 31, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) l: {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) var x; }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) return; }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch (e, s) while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 29, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 6),
      error(diag.expectedCatchClauseBody, 24, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 3),
      error(diag.expectedCatchClauseBody, 24, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A catch while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.catchSyntax, 24, 5),
      error(diag.expectedCatchClauseBody, 24, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 8),
      error(diag.expectedCatchClauseBody, 16, 8),
      error(diag.continueOutsideOfLoop, 16, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 2),
      error(diag.expectedCatchClauseBody, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 1),
      error(diag.expectedCatchClauseBody, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedCatchClauseBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A break; }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 16, 1),
      error(diag.breakOutsideOfLoop, 18, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 16, 1),
      error(diag.continueOutsideOfLoop, 18, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A l: {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A var x; }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A return; }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on A while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 2),
      error(diag.expectedCatchClauseBody, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedCatchClauseBody, 16, 1),
      error(diag.missingIdentifier, 17, 1),
      error(diag.expectedToken, 16, 1),
      error(diag.unexpectedToken, 17, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedCatchClauseBody, 16, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 4),
      error(diag.expectedCatchClauseBody, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedCatchClauseBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on return; }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 6),
      error(diag.expectedCatchClauseBody, 16, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 6),
      error(diag.expectedCatchClauseBody, 16, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 3),
      error(diag.expectedCatchClauseBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
    var parseResult = parseStringWithErrors(r'''
f() { try {} on while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedTypeName, 16, 5),
      error(diag.expectedCatchClauseBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
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
