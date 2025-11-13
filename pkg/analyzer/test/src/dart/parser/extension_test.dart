// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationParserTest);
  });
}

@reflectiveTest
class ExtensionDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment() {
    var parseResult = parseStringWithErrors(r'''
augment extension E {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  leftBracket: {
  rightBracket: }
''');
  }

  test_augment_generic() {
    var parseResult = parseStringWithErrors(r'''
augment extension E<T> {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  leftBracket: {
  rightBracket: }
''');
  }

  test_augment_hasOnClause() {
    var parseResult = parseStringWithErrors(r'''
augment extension E on int {}
''');
    parseResult.assertErrors([
      error(diag.extensionAugmentationHasOnClause, 20, 2),
    ]);

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  leftBracket: {
  rightBracket: }
''');
  }

  test_body_getter() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension E on int {
  int get foo => 0;
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: int
        propertyKeyword: get
        name: foo
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension E on int {
  int get foo => 0;
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleExtensionDeclaration;
      assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  leftBracket: {
  members
    MethodDeclaration
      returnType: NamedType
        name: int
      propertyKeyword: get
      name: foo
      body: ExpressionFunctionBody
        functionDefinition: =>
        expression: IntegerLiteral
          literal: 0
        semicolon: ;
  rightBracket: }
''');
    }
  }

  test_body_method() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension E on int {
  void foo() {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension E on int {
  void foo() {}
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleExtensionDeclaration;
      assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  leftBracket: {
  members
    MethodDeclaration
      returnType: NamedType
        name: void
      name: foo
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
  }

  test_body_setter() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension E on int {
  set foo(int _) {}
}
''');
    parseResult.assertNoErrors();
    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        propertyKeyword: set
        name: foo
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
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension E on int {
  set foo(int _) {}
}
''');
      parseResult.assertNoErrors();
      var node = parseResult.findNode.singleExtensionDeclaration;
      assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: E
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  leftBracket: {
  members
    MethodDeclaration
      propertyKeyword: set
      name: foo
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
  rightBracket: }
''');
    }
  }

  test_primaryConstructorBody() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension A on int {
  this;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  extensionKeyword: extension
  name: A
  onClause: ExtensionOnClause
    onKeyword: on
    extendedType: NamedType
      name: int
  body: BlockClassBody
    leftBracket: {
    members
      PrimaryConstructorBody
        thisKeyword: this
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');
  }
}
