// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclarationParserTest);
  });
}

@reflectiveTest
class ExtensionTypeDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment() {
    var parseResult = parseStringWithErrors(r'''
augment extension type A(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
  }

  test_error_fieldModifier_const() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(const int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifier, 17, 5),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(const int it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifier, 17, 5),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_fieldModifier_covariant() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifierInPrimaryConstructor, 17, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(covariant int it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifierInPrimaryConstructor, 17, 9),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_fieldModifier_covariant_final() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant final int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifierInPrimaryConstructor, 17, 9),
      error(ParserErrorCode.representationFieldModifier, 27, 5),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(covariant final int it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifierInPrimaryConstructor, 17, 9),
        error(ParserErrorCode.representationFieldModifier, 27, 5),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_fieldModifier_final() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(final int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.representationFieldModifier, 17, 5),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(final int it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.representationFieldModifier, 17, 5),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_fieldModifier_required() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(required int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifier, 17, 8),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(required int it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifier, 17, 8),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_fieldModifier_static() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(static int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifier, 17, 6),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(static int it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifier, 17, 6),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_fieldName_asDeclaration() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int A) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.memberWithClassName, 21, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: A
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(int A) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.memberWithClassName, 21, 1),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: A
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_formalParameterModifier_covariant_method_instance() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  void foo(covariant int a) {}
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifierInExtensionType, 38, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            covariantKeyword: covariant
            type: NamedType
              name: int
            name: a
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
extension type A(int it) {
  void foo(covariant int a) {}
}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifierInExtensionType, 38, 9),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  members
    MethodDeclaration
      returnType: NamedType
        name: void
      name: foo
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          covariantKeyword: covariant
          type: NamedType
            name: int
          name: a
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
  rightBracket: }
''');
    }
  }

  test_error_formalParameterModifier_covariant_method_static() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  static void foo(covariant int a) {}
}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.extraneousModifierInExtensionType, 45, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        modifierKeyword: static
        returnType: NamedType
          name: void
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            covariantKeyword: covariant
            type: NamedType
              name: int
            name: a
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
extension type A(int it) {
  static void foo(covariant int a) {}
}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.extraneousModifierInExtensionType, 45, 9),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  members
    MethodDeclaration
      modifierKeyword: static
      returnType: NamedType
        name: void
      name: foo
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          covariantKeyword: covariant
          type: NamedType
            name: int
          name: a
        rightParenthesis: )
      body: BlockFunctionBody
        block: Block
          leftBracket: {
          rightBracket: }
  rightBracket: }
''');
    }
  }

  test_error_multipleFields() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int a, String b) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.multipleRepresentationFields, 22, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(int a, String b) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.multipleRepresentationFields, 22, 1),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: a
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_noField() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A() {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedRepresentationField, 17, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> <synthetic>
        name: <empty> <synthetic>
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A() {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.expectedRepresentationField, 17, 1),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: <empty> <synthetic>
    fieldName: <empty> <synthetic>
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_noFieldType() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedRepresentationType, 17, 2),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> <synthetic>
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.expectedRepresentationType, 17, 2),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: <empty> <synthetic>
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_noFieldType_var() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(var it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedRepresentationType, 17, 3),
      error(ParserErrorCode.representationFieldModifier, 17, 3),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> <synthetic>
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(var it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.expectedRepresentationType, 17, 3),
        error(ParserErrorCode.representationFieldModifier, 17, 3),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: <empty> <synthetic>
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_superFormalParameter() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(super.it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedRepresentationField, 17, 5),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> <synthetic>
        name: <empty> <synthetic>
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(super.it) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.expectedRepresentationField, 17, 5),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: <empty> <synthetic>
    fieldName: <empty> <synthetic>
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_trailingComma() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int it,) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.representationFieldTrailingComma, 23, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(int it,) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.representationFieldTrailingComma, 23, 1),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_error_typeParameters_afterConstructorName() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A._<T>(T _) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedRepresentationField, 16, 0),
      error(ParserErrorCode.missingPrimaryConstructorParameters, 17, 1),
      error(ParserErrorCode.expectedExtensionTypeBody, 17, 1),
      error(ParserErrorCode.expectedExecutable, 18, 1),
      error(ParserErrorCode.missingConstFinalVarOrType, 19, 1),
      error(ParserErrorCode.expectedToken, 19, 1),
      error(ParserErrorCode.topLevelOperator, 20, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: _
    formalParameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> <synthetic>
        name: <empty> <synthetic>
      rightParenthesis: ) <synthetic>
  body: BlockClassBody
    leftBracket: { <synthetic>
    rightBracket: } <synthetic>
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A._<T>(T _) {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.expectedRepresentationField, 16, 0),
        error(ParserErrorCode.missingPrimaryConstructorParameters, 17, 1),
        error(ParserErrorCode.expectedExtensionTypeBody, 17, 1),
        error(ParserErrorCode.expectedExecutable, 18, 1),
        error(ParserErrorCode.missingConstFinalVarOrType, 19, 1),
        error(ParserErrorCode.expectedToken, 19, 1),
        error(ParserErrorCode.topLevelOperator, 20, 1),
      ]);

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    constructorName: RepresentationConstructorName
      period: .
      name: _
    leftParenthesis: ( <synthetic>
    fieldType: NamedType
      name: <empty> <synthetic>
    fieldName: <empty> <synthetic>
    rightParenthesis: ) <synthetic>
  leftBracket: { <synthetic>
  rightBracket: } <synthetic>
''');
    }
  }

  test_featureNotEnabled() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.1
class A {}
extension type B(int it) {}
class C {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.experimentNotEnabled, 36, 4),
    ]);

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      name: A
      leftBracket: {
      rightBracket: }
    ClassDeclaration
      classKeyword: class
      name: C
      leftBracket: {
      rightBracket: }
''');
  }

  test_field_metadata() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(@foo int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        metadata
          Annotation
            atSign: @
            name: SimpleIdentifier
              token: foo
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(@foo int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldMetadata
      Annotation
        atSign: @
        name: SimpleIdentifier
          token: foo
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_members_constructor() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  A.named(this.it);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    members
      ConstructorDeclaration
        returnType: SimpleIdentifier
          token: A
        period: .
        name: named
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: FieldFormalParameter
            thisKeyword: this
            period: .
            name: it
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  A.named(this.it);
}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  members
    ConstructorDeclaration
      returnType: SimpleIdentifier
        token: A
      period: .
      name: named
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: FieldFormalParameter
          thisKeyword: this
          period: .
          name: it
        rightParenthesis: )
      body: EmptyFunctionBody
        semicolon: ;
  rightBracket: }
''');
    }
  }

  test_members_field_instance() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  final int foo = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        fields: VariableDeclarationList
          keyword: final
          type: NamedType
            name: int
          variables
            VariableDeclaration
              name: foo
              equals: =
              initializer: IntegerLiteral
                literal: 0
        semicolon: ;
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  final int foo = 0;
}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  members
    FieldDeclaration
      fields: VariableDeclarationList
        keyword: final
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: foo
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
  rightBracket: }
''');
    }
  }

  test_members_field_static() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  static int foo = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  members
    FieldDeclaration
      staticKeyword: static
      fields: VariableDeclarationList
        type: NamedType
          name: int
        variables
          VariableDeclaration
            name: foo
            equals: =
            initializer: IntegerLiteral
              literal: 0
      semicolon: ;
  rightBracket: }
''');
  }

  test_members_getter() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  int get foo => 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
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

  test_members_method() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  void foo() {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
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

  test_members_setter() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  set foo(int _) {}
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
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

  test_metadata() {
    var parseResult = parseStringWithErrors(r'''
@foo
extension type A(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: foo
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
  }

  test_primaryConstructor_const_hasTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type const A<T, U>.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
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
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type const A<T, U>.named(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  constKeyword: const
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
      TypeParameter
        name: U
    rightBracket: >
  representation: RepresentationDeclaration
    constructorName: RepresentationConstructorName
      period: .
      name: named
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_const_hasTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type const A<T, U>(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
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
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type const A<T, U>(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  constKeyword: const
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
      TypeParameter
        name: U
    rightBracket: >
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type const A.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type const A.named(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  constKeyword: const
  name: A
  representation: RepresentationDeclaration
    constructorName: RepresentationConstructorName
      period: .
      name: named
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_const_noTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type const A(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type const A(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  constKeyword: const
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_const_typeName_noFormalParameters() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type const E {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.missingPrimaryConstructor, 21, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    constKeyword: const
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> <synthetic>
        name: <empty> <synthetic>
      rightParenthesis: ) <synthetic>
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  void test_primaryConstructor_missing() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type E {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.missingPrimaryConstructor, 15, 1),
    ]);

    var node = parseResult.findNode.extensionTypeDeclaration('E');
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension @0
  typeKeyword: type @10
  namePart: PrimaryConstructorDeclaration
    typeName: E @15
    formalParameters: FormalParameterList
      leftParenthesis: ( @17 <synthetic>
      parameter: SimpleFormalParameter
        type: NamedType
          name: <empty> @17 <synthetic>
        name: <empty> @17 <synthetic>
      rightParenthesis: ) @17 <synthetic>
  body: BlockClassBody
    leftBracket: { @17
    rightBracket: } @18
''', withOffsets: true);

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type E {}
''');
      parseResult.assertErrors([
        error(ParserErrorCode.missingPrimaryConstructor, 15, 1),
      ]);

      var node = parseResult.findNode.extensionTypeDeclaration('E');
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension @0
  typeKeyword: type @10
  name: E @15
  representation: RepresentationDeclaration
    leftParenthesis: ( @17 <synthetic>
    fieldType: NamedType
      name: <empty> @17 <synthetic>
    fieldName: <empty> @17 <synthetic>
    rightParenthesis: ) @17 <synthetic>
  leftBracket: { @17
  rightBracket: } @18
''', withOffsets: true);
    }
  }

  test_primaryConstructor_notConst_hasTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A<T, U>.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A<T, U>.named(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
      TypeParameter
        name: U
    rightBracket: >
  representation: RepresentationDeclaration
    constructorName: RepresentationConstructorName
      period: .
      name: named
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_notConst_hasTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A<T, U>(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
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
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A<T, U>(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
      TypeParameter
        name: U
    rightBracket: >
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_notConst_noTypeParameters_named() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    constructorName: PrimaryConstructorName
      period: .
      name: named
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A.named(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    constructorName: RepresentationConstructorName
      period: .
      name: named
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_primaryConstructor_notConst_noTypeParameters_unnamed() {
    useDeclaringConstructorsAst = true;
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');

    {
      useDeclaringConstructorsAst = false;
      var parseResult = parseStringWithErrors(r'''
extension type A(int it) {}
''');
      parseResult.assertNoErrors();

      var node = parseResult.findNode.singleExtensionTypeDeclaration;
      assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
    }
  }

  test_withImplementsClause() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) implements B, C {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: B
      NamedType
        name: C
  leftBracket: {
  rightBracket: }
''');
  }

  test_withTypeParameters() {
    var parseResult = parseStringWithErrors(r'''
extension type A<T>(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
    fieldName: it
    rightParenthesis: )
  leftBracket: {
  rightBracket: }
''');
  }
}
