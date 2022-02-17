// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AstBuilderTest);
  });
}

@reflectiveTest
class AstBuilderTest extends ParserDiagnosticsTest {
  void test_constructor_factory_misnamed() {
    var parseResult = parseStringWithErrors(r'''
class A {
  factory B() => null;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  body: ExpressionFunctionBody
    expression: NullLiteral
      literal: null
    functionDefinition: =>
    semicolon: ;
  factoryKeyword: factory
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  returnType: SimpleIdentifier
    token: B
''');
  }

  void test_constructor_wrongName() {
    var parseResult = parseStringWithErrors(r'''
class A {
  B() : super();
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.INVALID_CONSTRUCTOR_NAME, 12, 1),
    ]);

    var node = parseResult.findNode.constructor('B()');
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  body: EmptyFunctionBody
    semicolon: ;
  initializers
    SuperConstructorInvocation
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      superKeyword: super
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  returnType: SimpleIdentifier
    token: B
''');
  }

  void test_enum_constant_name_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 14, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    constructorSelector: ConstructorSelector
      name: SimpleIdentifier
        token: <empty> <synthetic>
      period: .
  name: SimpleIdentifier
    token: v
''');
  }

  void test_enum_constant_name_dot_identifier_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.named;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    constructorSelector: ConstructorSelector
      name: SimpleIdentifier
        token: named
      period: .
  name: SimpleIdentifier
    token: v
''');
  }

  void test_enum_constant_name_dot_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MISSING_IDENTIFIER, 13, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    constructorSelector: ConstructorSelector
      name: SimpleIdentifier
        token: <empty> <synthetic>
      period: .
  name: SimpleIdentifier
    token: v
''');
  }

  void test_enum_constant_name_typeArguments_dot() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ENUM_CONSTANT_WITH_TYPE_ARGUMENTS_WITHOUT_ARGUMENTS,
          12, 5),
      error(ParserErrorCode.MISSING_IDENTIFIER, 19, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v<int>.');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    constructorSelector: ConstructorSelector
      name: SimpleIdentifier
        token: <empty> <synthetic>
      period: .
    typeArguments: TypeArgumentList
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      leftBracket: <
      rightBracket: >
  name: SimpleIdentifier
    token: v
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/48380')
  void test_enum_constant_name_typeArguments_dot_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v<int>.;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ENUM_CONSTANT_WITH_TYPE_ARGUMENTS_WITHOUT_ARGUMENTS,
          12, 5),
      error(ParserErrorCode.MISSING_IDENTIFIER, 18, 1),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(
        node,
        r'''
EnumConstantDeclaration
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    constructorSelector: ConstructorSelector
      name: SimpleIdentifier
        token: <empty> <synthetic>
      period: .
    typeArguments: TypeArgumentList
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      leftBracket: <
      rightBracket: >
  name: SimpleIdentifier
    token: v
''',
        withCheckingLinking: true);
  }

  void test_enum_constant_withTypeArgumentsWithoutArguments() {
    var parseResult = parseStringWithErrors(r'''
enum E<T> {
  v<int>;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.ENUM_CONSTANT_WITH_TYPE_ARGUMENTS_WITHOUT_ARGUMENTS,
          15, 5),
    ]);

    var node = parseResult.findNode.enumConstantDeclaration('v<int>');
    assertParsedNodeText(node, r'''
EnumConstantDeclaration
  arguments: EnumConstantArguments
    argumentList: ArgumentList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    typeArguments: TypeArgumentList
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
      leftBracket: <
      rightBracket: >
  name: SimpleIdentifier
    token: v
''');
  }

  void test_enum_semicolon_null() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  constants
    EnumConstantDeclaration
      name: SimpleIdentifier
        token: v
  name: SimpleIdentifier
    token: E
''');
  }

  void test_enum_semicolon_optional() {
    var parseResult = parseStringWithErrors(r'''
enum E {
  v;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.enumDeclaration('enum E');
    assertParsedNodeText(node, r'''
EnumDeclaration
  constants
    EnumConstantDeclaration
      name: SimpleIdentifier
        token: v
  name: SimpleIdentifier
    token: E
  semicolon: ;
''');
  }

  void test_getter_sameNameAsClass() {
    var parseResult = parseStringWithErrors(r'''
class A {
  get A => 0;
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MEMBER_WITH_CLASS_NAME, 16, 1),
    ]);

    var node = parseResult.findNode.methodDeclaration('get A');
    assertParsedNodeText(node, r'''
MethodDeclaration
  body: ExpressionFunctionBody
    expression: IntegerLiteral
      literal: 0
    functionDefinition: =>
    semicolon: ;
  name: SimpleIdentifier
    token: A
  propertyKeyword: get
''');
  }

  void test_superFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
class A {
  A(super.a);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.superFormalParameter('super.a');
    assertParsedNodeText(node, r'''
SuperFormalParameter
  identifier: SimpleIdentifier
    token: a
  period: .
  superKeyword: super
''');
  }
}
