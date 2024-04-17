// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelFunctionParserTest);
  });
}

@reflectiveTest
class TopLevelFunctionParserTest extends ParserDiagnosticsTest {
  test_function_augment() {
    var parseResult = parseStringWithErrors(r'''
augment library 'a.dart';
augment void foo() {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }

  test_getter_augment() {
    var parseResult = parseStringWithErrors(r'''
augment library 'a.dart';
augment int get foo => 0;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: int
  propertyKeyword: get
  name: foo
  functionExpression: FunctionExpression
    body: ExpressionFunctionBody
      functionDefinition: =>
      expression: IntegerLiteral
        literal: 0
      semicolon: ;
''');
  }

  test_setter_augment() {
    var parseResult = parseStringWithErrors(r'''
augment library 'a.dart';
augment set foo(int _) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  propertyKeyword: set
  name: foo
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: _
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
''');
  }
}
