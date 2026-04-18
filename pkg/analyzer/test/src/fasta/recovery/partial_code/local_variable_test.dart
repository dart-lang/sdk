// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../dart/resolution/node_text_expectations.dart';
import '../../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LocalVariableTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LocalVariableTest extends ParserDiagnosticsTest {
  void test_local_variable_const_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const assert (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: assert
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_const_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 13, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SetOrMapLiteral
                  constKeyword: const
                  leftBracket: {
                  rightBracket: }
                  isMap: false
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_const_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const break; }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 5),
      error(diag.expectedToken, 12, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: break
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_const_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 8),
      error(diag.expectedToken, 12, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: continue
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_const_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 2),
      error(diag.expectedToken, 12, 2),
      error(diag.expectedToken, 12, 2),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: do
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
              WhileStatement
                whileKeyword: while
                leftParenthesis: (
                condition: BooleanLiteral
                  literal: true
                rightParenthesis: )
                body: EmptyStatement
                  semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_const_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 1),
      error(diag.expectedToken, 12, 1),
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
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: <empty> <synthetic>
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_const_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 3),
      error(diag.missingIdentifier, 17, 3),
      error(diag.expectedToken, 17, 3),
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
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: for
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      SimpleIdentifier
                        token: <empty> <synthetic>
                    rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_const_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 2),
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
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: if
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_const_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.unexpectedToken, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: l
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
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

  void test_local_variable_const_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int f() {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 6, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_const_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const void f() {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 6, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_const_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const var x; }
''');
    parseResult.assertErrors([error(diag.conflictingModifiers, 12, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_const_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const return; }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 6),
      error(diag.expectedToken, 12, 6),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: return
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_const_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 6),
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
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: switch
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      SimpleIdentifier
                        token: x
                    rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_const_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 3),
      error(diag.expectedToken, 12, 3),
      error(diag.expectedToken, 12, 3),
      error(diag.expectedIdentifierButGotKeyword, 19, 7),
      error(diag.expectedToken, 19, 7),
      error(diag.missingStatement, 19, 7),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: try
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
              ExpressionStatement
                expression: SimpleIdentifier
                  token: finally
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_const_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.expectedIdentifierButGotKeyword, 12, 5),
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
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: while
                  argumentList: ArgumentList
                    leftParenthesis: (
                    arguments
                      BooleanLiteral
                        literal: true
                    rightParenthesis: )
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const a {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.breakOutsideOfLoop, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.continueOutsideOfLoop, 14, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const a do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const a }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
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
              ExpressionStatement
                expression: InstanceCreationExpression
                  keyword: const
                  constructorName: ConstructorName
                    type: NamedType
                      name: a
                  argumentList: ArgumentList
                    leftParenthesis: ( <synthetic>
                    rightParenthesis: ) <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_constName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const a for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const a if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.missingIdentifier, 15, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: a
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const a int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: a
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const a return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
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

  void test_local_variable_constNameComma_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, assert (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, {} }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constNameComma_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 5),
      error(diag.expectedToken, 13, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constNameComma_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 8),
      error(diag.expectedToken, 13, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constNameComma_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_constNameComma_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
      error(diag.missingIdentifier, 16, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
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

  void test_local_variable_constNameComma_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 15, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
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

  void test_local_variable_constNameComma_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, void f() {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 4),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, var x; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, return; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constNameComma_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameComma_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 15, 5),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constNameCommaName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b assert (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constNameCommaName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constNameCommaName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 15, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constNameCommaName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b do {} while (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_constNameCommaName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b for (var x in y) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b if (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b l: {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b int f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b void f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b var x; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b return; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constNameCommaName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b switch (x) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b try {} finally {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constNameCommaName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const a, b while (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constTypeName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_constTypeName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_constTypeNameComma_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, assert (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, {} }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameComma_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 5),
      error(diag.expectedToken, 17, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameComma_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 8),
      error(diag.expectedToken, 17, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameComma_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameComma_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
      error(diag.missingIdentifier, 20, 1),
      error(diag.unexpectedToken, 20, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
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

  void test_local_variable_constTypeNameComma_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 19, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
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

  void test_local_variable_constTypeNameComma_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, void f() {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 4),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, var x; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, return; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameComma_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameComma_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 19, 5),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_constTypeNameCommaName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b assert (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameCommaName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameCommaName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 19, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameCommaName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b do {} while (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameCommaName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b for (var x in y) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b if (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b l: {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b int f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b void f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b var x; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b return; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_constTypeNameCommaName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b switch (x) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b try {} finally {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_constTypeNameCommaName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { const int a, b while (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: const
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                    VariableDeclaration
                      name: b
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

  void test_local_variable_final_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { final assert (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_final_block() {
    var parseResult = parseStringWithErrors(r'''
f() { final {} }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_final_break() {
    var parseResult = parseStringWithErrors(r'''
f() { final break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 5),
      error(diag.expectedToken, 6, 5),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_final_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { final continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 8),
      error(diag.expectedToken, 6, 5),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_final_do() {
    var parseResult = parseStringWithErrors(r'''
f() { final do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_final_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { final }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_final_for() {
    var parseResult = parseStringWithErrors(r'''
f() { final for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_final_if() {
    var parseResult = parseStringWithErrors(r'''
f() { final if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_final_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { final l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.unexpectedToken, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_final_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { final int f() {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 6, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_final_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { final void f() {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 6, 5)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_final_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { final var x; }
''');
    parseResult.assertErrors([error(diag.finalAndVar, 12, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: x
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_final_return() {
    var parseResult = parseStringWithErrors(r'''
f() { final return; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_final_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { final switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 6),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_final_try() {
    var parseResult = parseStringWithErrors(r'''
f() { final try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_final_while() {
    var parseResult = parseStringWithErrors(r'''
f() { final while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 12, 5),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_finalName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { final a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { final a {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_finalName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { final a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.breakOutsideOfLoop, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_finalName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { final a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 12, 1),
      error(diag.continueOutsideOfLoop, 14, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_finalName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { final a do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { final a }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_finalName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { final a for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { final a if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { final a l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.missingIdentifier, 15, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: a
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { final a int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: a
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { final a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { final a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { final a return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_finalName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { final a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { final a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { final a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 12, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_finalTypeName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_finalTypeName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 16, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_finalTypeName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_finalTypeName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_finalTypeName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_finalTypeName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { final int a while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 16, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: final
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_type_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { int assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_block() {
    var parseResult = parseStringWithErrors(r'''
f() { int {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_type_break() {
    var parseResult = parseStringWithErrors(r'''
f() { int break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 6, 3),
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
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_type_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { int continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 6, 3),
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
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_type_do() {
    var parseResult = parseStringWithErrors(r'''
f() { int do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { int }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_type_for() {
    var parseResult = parseStringWithErrors(r'''
f() { int for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_if() {
    var parseResult = parseStringWithErrors(r'''
f() { int if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { int l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 11, 1),
      error(diag.unexpectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_type_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { int int f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_type_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { int void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { int var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_return() {
    var parseResult = parseStringWithErrors(r'''
f() { int return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_type_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { int switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_try() {
    var parseResult = parseStringWithErrors(r'''
f() { int try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_type_while() {
    var parseResult = parseStringWithErrors(r'''
f() { int while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: int
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

  void test_local_variable_typeName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { int a assert (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { int a {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_typeName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { int a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_typeName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { int a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_typeName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { int a do {} while (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { int a }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_typeName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { int a for (var x in y) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { int a if (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { int a l: {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { int a int f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { int a void f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { int a var x; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { int a return; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_typeName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { int a switch (x) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { int a try {} finally {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_typeName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { int a while (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  type: NamedType
                    name: int
                  variables
                    VariableDeclaration
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

  void test_local_variable_var_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { var assert (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 6),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_var_block() {
    var parseResult = parseStringWithErrors(r'''
f() { var {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 1),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_var_break() {
    var parseResult = parseStringWithErrors(r'''
f() { var break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 5),
      error(diag.expectedToken, 6, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_var_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { var continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 8),
      error(diag.expectedToken, 6, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_var_do() {
    var parseResult = parseStringWithErrors(r'''
f() { var do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 2),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_var_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { var }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 1),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_var_for() {
    var parseResult = parseStringWithErrors(r'''
f() { var for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 3),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_var_if() {
    var parseResult = parseStringWithErrors(r'''
f() { var if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 2),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_var_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { var l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
      error(diag.missingIdentifier, 11, 1),
      error(diag.unexpectedToken, 11, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_var_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var int f() {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_var_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var void f() {} }
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 6, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_var_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { var var x; }
''');
    parseResult.assertErrors([error(diag.duplicatedModifier, 10, 3)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
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

  void test_local_variable_var_return() {
    var parseResult = parseStringWithErrors(r'''
f() { var return; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 6),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_var_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { var switch (x) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 6),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_var_try() {
    var parseResult = parseStringWithErrors(r'''
f() { var try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 3),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_var_while() {
    var parseResult = parseStringWithErrors(r'''
f() { var while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 10, 5),
      error(diag.expectedToken, 6, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: <empty> <synthetic>
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

  void test_local_variable_varName_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { var a assert (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_block() {
    var parseResult = parseStringWithErrors(r'''
f() { var a {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_varName_break() {
    var parseResult = parseStringWithErrors(r'''
f() { var a break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varName_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { var a continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 10, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varName_do() {
    var parseResult = parseStringWithErrors(r'''
f() { var a do {} while (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { var a }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varName_for() {
    var parseResult = parseStringWithErrors(r'''
f() { var a for (var x in y) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_if() {
    var parseResult = parseStringWithErrors(r'''
f() { var a if (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { var a l: {} }
''');
    parseResult.assertErrors([
      error(diag.varAndType, 6, 3),
      error(diag.expectedToken, 12, 1),
      error(diag.missingIdentifier, 13, 1),
      error(diag.unexpectedToken, 13, 1),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  type: NamedType
                    name: a
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var a int f() {} }
''');
    parseResult.assertErrors([
      error(diag.varAndType, 6, 3),
      error(diag.expectedToken, 12, 3),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  type: NamedType
                    name: a
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var a void f() {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { var a var x; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_return() {
    var parseResult = parseStringWithErrors(r'''
f() { var a return; }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varName_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { var a switch (x) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_try() {
    var parseResult = parseStringWithErrors(r'''
f() { var a try {} finally {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varName_while() {
    var parseResult = parseStringWithErrors(r'''
f() { var a while (true) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
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

  void test_local_variable_varNameEquals_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = assert (true); }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
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
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_block() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SetOrMapLiteral
                        leftBracket: {
                        rightBracket: }
                        isMap: false
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_break() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = break; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 5),
      error(diag.expectedToken, 12, 1),
      error(diag.breakOutsideOfLoop, 14, 5),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: <empty> <synthetic>
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = continue; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 8),
      error(diag.expectedToken, 12, 1),
      error(diag.continueOutsideOfLoop, 14, 8),
    ]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: <empty> <synthetic>
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_do() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = do {} while (true); }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
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

  void test_local_variable_varNameEquals_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: <empty> <synthetic>
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_for() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = for (var x in y) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
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

  void test_local_variable_varNameEquals_if() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = if (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 2),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
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

  void test_local_variable_varNameEquals_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = l: {} }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
      error(diag.missingIdentifier, 15, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: l
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

  void test_local_variable_varNameEquals_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = int f() {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 18, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: FunctionExpression
                        parameters: FormalParameterList
                          leftParenthesis: (
                          rightParenthesis: )
                        body: BlockFunctionBody
                          block: Block
                            leftBracket: {
                            rightBracket: }
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = void f() {} }
''');
    parseResult.assertErrors([
      error(diag.namedFunctionExpression, 19, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: FunctionExpression
                        parameters: FormalParameterList
                          leftParenthesis: (
                          rightParenthesis: )
                        body: BlockFunctionBody
                          block: Block
                            leftBracket: {
                            rightBracket: }
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = var x; }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
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

  void test_local_variable_varNameEquals_return() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = return; }
''');
    parseResult.assertErrors([
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: <empty> <synthetic>
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = switch (x) {} }
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SwitchExpression
                        switchKeyword: switch
                        leftParenthesis: (
                        expression: SimpleIdentifier
                          token: x
                        rightParenthesis: )
                        leftBracket: {
                        rightBracket: }
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varNameEquals_try() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = try {} finally {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 3),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
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

  void test_local_variable_varNameEquals_while() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = while (true) {} }
''');
    parseResult.assertErrors([
      error(diag.missingIdentifier, 14, 5),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
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

  void test_local_variable_varNameEqualsExpression_assert() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b assert (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_block() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
                semicolon: ; <synthetic>
              Block
                leftBracket: {
                rightBracket: }
            rightBracket: }
''');
  }

  void test_local_variable_varNameEqualsExpression_break() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b break; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
                semicolon: ; <synthetic>
              BreakStatement
                breakKeyword: break
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEqualsExpression_continue() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b continue; }
''');
    parseResult.assertErrors([
      error(diag.expectedToken, 14, 1),
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
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
                semicolon: ; <synthetic>
              ContinueStatement
                continueKeyword: continue
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEqualsExpression_do() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b do {} while (true); }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_eof() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
                semicolon: ; <synthetic>
            rightBracket: }
''');
  }

  void test_local_variable_varNameEqualsExpression_for() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b for (var x in y) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_if() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b if (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_labeled() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b l: {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_localFunctionNonVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b int f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_localFunctionVoid() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b void f() {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_localVariable() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b var x; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_return() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b return; }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
                semicolon: ; <synthetic>
              ReturnStatement
                returnKeyword: return
                semicolon: ;
            rightBracket: }
''');
  }

  void test_local_variable_varNameEqualsExpression_switch() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b switch (x) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_try() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b try {} finally {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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

  void test_local_variable_varNameEqualsExpression_while() {
    var parseResult = parseStringWithErrors(r'''
f() { var a = b while (true) {} }
''');
    parseResult.assertErrors([error(diag.expectedToken, 14, 1)]);
    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    FunctionDeclaration
      name: f
      functionExpression: FunctionExpression
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              VariableDeclarationStatement
                variables: VariableDeclarationList
                  keyword: var
                  variables
                    VariableDeclaration
                      name: a
                      equals: =
                      initializer: SimpleIdentifier
                        token: b
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
