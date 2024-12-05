// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationParserTest);
  });
}

@reflectiveTest
class EnumDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment_constant_add() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {
  v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
  }

  test_augment_constant_augment_noConstructor() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {
  augment v
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      augmentKeyword: augment
      name: v
  rightBracket: }
''');
  }

  test_augment_constant_augment_withConstructor() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {
  augment v.foo()
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      augmentKeyword: augment
      name: v
      arguments: EnumConstantArguments
        constructorSelector: ConstructorSelector
          period: .
          name: SimpleIdentifier
            token: foo
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
  rightBracket: }
''');
  }

  test_augment_noConstants_semicolon_method() {
    var parseResult = parseStringWithErrors(r'''
augment enum E {;
  void foo() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  name: E
  leftBracket: {
  semicolon: ;
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

  test_declaration_empty() {
    var parseResult = parseStringWithErrors(r'''
enum E {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  rightBracket: }
''');
  }

  test_declaration_noConstants_semicolon() {
    var parseResult = parseStringWithErrors(r'''
enum E {;}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  semicolon: ;
  rightBracket: }
''');
  }

  test_declaration_noConstants_semicolon_method() {
    var parseResult = parseStringWithErrors(r'''
enum E {;
  void foo() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  semicolon: ;
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
