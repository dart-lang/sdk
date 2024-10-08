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

  test_recovery_body_issue56355() {
    // https://github.com/dart-lang/sdk/issues/56355
    var parseResult = parseStringWithErrors(r'''
void get() {
  http.Response response = http
}
''');

    // Note, there is a cycle that should not be there.
    var node = parseResult.findNode.singleFunctionDeclaration;
    assertParsedNodeText(
      node,
      withTokenPreviousNext: true,
      withOffsets: true,
      r'''
FunctionDeclaration
  returnType: NamedType
    name: T0 void @0
      next: T1 |get|
  name: T1 get @5
    previous: T0 |void|
    next: T2 |(|
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: T2 ( @8
        previous: T1 |get|
        next: T3 |)|
      rightParenthesis: T3 ) @9
        previous: T2 |(|
        next: T4 |{|
    body: BlockFunctionBody
      block: Block
        leftBracket: T4 { @11
          previous: T3 |)|
          next: T5 |http|
        statements
          ExpressionStatement
            expression: PrefixedIdentifier
              prefix: SimpleIdentifier
                token: T5 http @15
                  previous: T4 |{|
                  next: T6 |.|
              period: T6 . @19
                previous: T5 |http|
                next: T7 |Response|
              identifier: SimpleIdentifier
                token: T7 Response @20
                  previous: T6 |.|
                  next: T8 |response|
            semicolon: T9 ; @45 <synthetic>
              previousX: T10 http @40
                previousX: T11 = @38
                  previous: T8 |response|
                  next: T10 |http|
                next: T9 |;|
              next: T8 |response|
          ExpressionStatement
            expression: SimpleIdentifier
              token: T8 response @29
                previous: T9 |;|
                next: T12 |;|
            semicolon: T12 ; @45 <synthetic>
              previous: T8 |response|
              next: T13 |}|
        rightBracket: T13 } @45
          previous: T12 |;|
          next: T14 ||
''',
    );
  }

  test_setter_augment() {
    var parseResult = parseStringWithErrors(r'''
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
