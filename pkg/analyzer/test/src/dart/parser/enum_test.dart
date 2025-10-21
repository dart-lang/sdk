// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
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

  test_nameWithTypeParameters_hasTypeParameters() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum E<T, U> {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
enum E<T, U> {v}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleEnumDeclaration;
      assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
      TypeParameter
        name: U
    rightBracket: >
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
    }
  }

  test_nameWithTypeParameters_noTypeParameters() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum E {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
enum E {v}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleEnumDeclaration;
      assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: v
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_const_hasTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum const E<T, U>.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_hasTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum const E<T, U>() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum const E.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_noTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum const E() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_const_typeName_noFormalParameters() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum const E {v}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.constWithoutPrimaryConstructor, 5, 5),
    ]);

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: E
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_hasTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum E<T, U>.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_hasTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum E<T, U>() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
        TypeParameter
          name: U
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_noTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum E.named() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }

  test_primaryConstructor_notConst_noTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
enum E() {v}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  enumKeyword: enum
  namePart: PrimaryConstructorDeclaration
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
  body: EnumBody
    leftBracket: {
    constants
      EnumConstantDeclaration
        name: v
    rightBracket: }
''');
  }
}
