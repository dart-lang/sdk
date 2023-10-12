// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_error_fieldModifier_const() {
    final parseResult = parseStringWithErrors(r'''
extension type A(const int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 17, 5),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_fieldModifier_final() {
    final parseResult = parseStringWithErrors(r'''
extension type A(final int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.REPRESENTATION_FIELD_MODIFIER, 17, 5),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_fieldModifier_required() {
    final parseResult = parseStringWithErrors(r'''
extension type A(required int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 17, 8),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_fieldModifier_static() {
    final parseResult = parseStringWithErrors(r'''
extension type A(static int it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXTRANEOUS_MODIFIER, 17, 6),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_multipleFields() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int a, String b) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.MULTIPLE_REPRESENTATION_FIELDS, 22, 1),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_noField() {
    final parseResult = parseStringWithErrors(r'''
extension type A() {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_REPRESENTATION_FIELD, 17, 1),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_noFieldType() {
    final parseResult = parseStringWithErrors(r'''
extension type A(it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_REPRESENTATION_TYPE, 17, 2),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_superFormalParameter() {
    final parseResult = parseStringWithErrors(r'''
extension type A(super.it) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_REPRESENTATION_FIELD, 17, 5),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_trailingComma() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int it,) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.REPRESENTATION_FIELD_TRAILING_COMMA, 23, 1),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_error_typeParameters_afterConstructorName() {
    final parseResult = parseStringWithErrors(r'''
extension type A._<T>(T _) {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_REPRESENTATION_FIELD, 16, 0),
      error(ParserErrorCode.MISSING_PRIMARY_CONSTRUCTOR_PARAMETERS, 17, 1),
      error(ParserErrorCode.EXPECTED_EXTENSION_TYPE_BODY, 17, 1),
      error(ParserErrorCode.EXPECTED_EXECUTABLE, 18, 1),
      error(ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE, 19, 1),
      error(ParserErrorCode.EXPECTED_TOKEN, 19, 1),
      error(ParserErrorCode.TOP_LEVEL_OPERATOR, 20, 1),
    ]);

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_featureNotEnabled() {
    final parseResult = parseStringWithErrors(r'''
// @dart = 3.1
class A {}
extension type B(int it) {}
class C {}
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 36, 4),
    ]);

    final node = parseResult.findNode.unit;
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
    final parseResult = parseStringWithErrors(r'''
extension type A(@foo int it) {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_members_constructor() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  A.named(this.it);
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_members_field_instance() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  final int foo = 0;
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_members_field_static() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  static int foo = 0;
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  int get foo => 0;
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  void foo() {}
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  set foo(int _) {}
}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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
    final parseResult = parseStringWithErrors(r'''
@foo
extension type A(int it) {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_primaryConstructor_const() {
    final parseResult = parseStringWithErrors(r'''
extension type const A(int it) {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_primaryConstructor_named() {
    final parseResult = parseStringWithErrors(r'''
extension type A.named(int it) {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_primaryConstructor_unnamed() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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

  test_withImplementsClause() {
    final parseResult = parseStringWithErrors(r'''
extension type A(int it) implements B, C {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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
    final parseResult = parseStringWithErrors(r'''
extension type A<T>(int it) {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionTypeDeclaration;
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
