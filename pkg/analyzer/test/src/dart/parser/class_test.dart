// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationParserTest);
  });
}

@reflectiveTest
class ClassDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment_constructor_named() {
    var parseResult = parseStringWithErrors(r'''
augment class A {
  augment A.named();
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleClassDeclaration;
    assertParsedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  name: A
  leftBracket: {
  members
    ConstructorDeclaration
      augmentKeyword: augment
      returnType: SimpleIdentifier
        token: A
      period: .
      name: named
      parameters: FormalParameterList
        leftParenthesis: (
        rightParenthesis: )
      body: EmptyFunctionBody
        semicolon: ;
  rightBracket: }
''');
  }

  test_constructor_external_fieldFormalParameter_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int f;
  external A([this.f = 0]);
}
''');
    parseResult.assertErrors([
      error(
          ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS, 39, 4),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  returnType: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: DefaultFormalParameter
      parameter: FieldFormalParameter
        thisKeyword: this
        period: .
        name: f
      separator: =
      defaultValue: IntegerLiteral
        literal: 0
    rightDelimiter: ]
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_external_fieldFormalParameter_requiredPositional() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int f;
  external A(this.f);
}
''');
    parseResult.assertErrors([
      error(
          ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_FIELD_INITIALIZERS, 38, 4),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  returnType: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: FieldFormalParameter
      thisKeyword: this
      period: .
      name: f
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_external_fieldInitializer() {
    var parseResult = parseStringWithErrors(r'''
class A {
  final int f;
  external A() : f = 0;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTERNAL_CONSTRUCTOR_WITH_INITIALIZER, 40, 1),
    ]);

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  externalKeyword: external
  returnType: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      fieldName: SimpleIdentifier
        token: f
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }
}
