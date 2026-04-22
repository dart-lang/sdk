// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedSwitchStatementBody, 16, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedSwitchStatementBody, 16, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.expectedSwitchStatementBody, 16, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedSwitchStatementBody, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
      error(diag.expectedSwitchStatementBody, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedSwitchStatementBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedSwitchStatementBody, 16, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.expectedSwitchStatementBody, 16, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.expectedSwitchStatementBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedSwitchStatementBody, 16, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.expectedSwitchStatementBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
      error(diag.expectedSwitchStatementBody, 16, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedSwitchStatementBody, 16, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedSwitchStatementBody, 16, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedSwitchStatementBody, 16, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 6),
      error(diag.missingIdentifier, 13, 6),
      error(diag.expectedSwitchStatementBody, 13, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.missingIdentifier, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 5),
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedSwitchStatementBody, 13, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 8),
      error(diag.missingIdentifier, 13, 8),
      error(diag.expectedSwitchStatementBody, 13, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 2),
      error(diag.missingIdentifier, 13, 2),
      error(diag.expectedSwitchStatementBody, 13, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.expectedSwitchStatementBody, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedSwitchStatementBody, 13, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 2),
      error(diag.missingIdentifier, 13, 2),
      error(diag.expectedSwitchStatementBody, 13, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.expectedSwitchStatementBody, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedSwitchStatementBody, 13, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 4),
      error(diag.missingIdentifier, 13, 4),
      error(diag.expectedSwitchStatementBody, 13, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedSwitchStatementBody, 13, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 6),
      error(diag.missingIdentifier, 13, 6),
      error(diag.expectedSwitchStatementBody, 13, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 6),
      error(diag.missingIdentifier, 13, 6),
      error(diag.expectedSwitchStatementBody, 13, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 3),
      error(diag.missingIdentifier, 13, 3),
      error(diag.expectedSwitchStatementBody, 13, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 13, 5),
      error(diag.missingIdentifier, 13, 5),
      error(diag.expectedSwitchStatementBody, 13, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 36, 1),
      error(diag.expectedToken, 19, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 24, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.expectedToken, 19, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 19, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { }
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 41, 1),
      error(diag.expectedToken, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 34, 1),
      error(diag.expectedToken, 19, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 32, 1),
      error(diag.expectedToken, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.expectedToken, 19, 4),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.expectedToken, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedToken, 19, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.expectedToken, 19, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 39, 1),
      error(diag.expectedToken, 19, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) { while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 37, 1),
      error(diag.expectedToken, 19, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 30, 1),
      error(diag.expectedSwitchStatementBody, 28, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 18, 1),
      error(diag.expectedSwitchStatementBody, 18, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedSwitchStatementBody, 15, 5),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 25, 1),
      error(diag.missingIdentifier, 15, 8),
      error(diag.expectedSwitchStatementBody, 15, 8),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 2),
      error(diag.expectedSwitchStatementBody, 15, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 15, 1),
      error(diag.expectedSwitchStatementBody, 15, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 35, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedSwitchStatementBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 28, 1),
      error(diag.missingIdentifier, 15, 2),
      error(diag.expectedSwitchStatementBody, 15, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 21, 1),
      error(diag.expectedSwitchStatementBody, 16, 1),
      error(diag.missingIdentifier, 16, 1),
      error(diag.expectedToken, 15, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( int f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 26, 1),
      error(diag.namedFunctionExpression, 19, 1),
      error(diag.expectedSwitchStatementBody, 26, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( void f() {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 27, 1),
      error(diag.namedFunctionExpression, 20, 1),
      error(diag.expectedSwitchStatementBody, 27, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( var x; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 22, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedSwitchStatementBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( return; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 23, 1),
      error(diag.unexpectedToken, 15, 6),
      error(diag.missingIdentifier, 21, 1),
      error(diag.expectedSwitchStatementBody, 21, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 29, 1),
      error(diag.expectedSwitchStatementBody, 29, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 33, 1),
      error(diag.missingIdentifier, 15, 3),
      error(diag.expectedSwitchStatementBody, 15, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch ( while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 31, 1),
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedSwitchStatementBody, 15, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) {} }
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) break; }
''');
    parseResult.assertErrors([
      error(diag.expectedSwitchStatementBody, 15, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedSwitchStatementBody, 15, 1),
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) l: {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) var x; }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) return; }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
    var parseResult = parseStringWithErrors(r'''
f() { switch (a) while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedSwitchStatementBody, 15, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
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
