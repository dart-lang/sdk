// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclarationParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_body_empty() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it);
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_constructor_factoryHead_named() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  factory named() => A(0);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: A
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
        rightParenthesis: )
    semicolon: ;
''');
  }

  test_constructor_factoryHead_named_const() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  const factory named() = B;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: B
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_factoryHead_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  factory () => A(0);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: A
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
        rightParenthesis: )
    semicolon: ;
''');
  }

  test_constructor_factoryHead_unnamed_const() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  const factory () = B;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: B
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_named() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  new named() : this.it = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: it
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_named_const() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  const new named() : this.it = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  newKeyword: new
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: it
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  new () : this.it = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: it
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_newHead_unnamed_const() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  const new () : this.it = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  newKeyword: new
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: it
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_factory_named() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  factory A.named() => A(0);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: A
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
        rightParenthesis: )
    semicolon: ;
''');
  }

  test_constructor_typeName_factory_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  factory A() => A(0);
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: A
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
        rightParenthesis: )
    semicolon: ;
''');
  }

  test_constructor_typeName_named() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  A.named() : this.it = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: it
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_constructor_typeName_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  A() : this.it = 0;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  separator: :
  initializers
    ConstructorFieldInitializer
      thisKeyword: this
      period: .
      fieldName: SimpleIdentifier
        token: it
      equals: =
      expression: IntegerLiteral
        literal: 0
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_error_fieldModifier_const() {
    var parseResult = parseStringWithErrors(r'''
extension type A(const int it) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 5)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldModifier_covariant() {
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant int it) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifierInPrimaryConstructor, 17, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldModifier_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant final int it) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifierInPrimaryConstructor, 17, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldModifier_final() {
    var parseResult = parseStringWithErrors(r'''
extension type A(final int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldModifier_final_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(final int it) {}
''');
    parseResult.assertErrors([error(diag.representationFieldModifier, 33, 5)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldModifier_required() {
    var parseResult = parseStringWithErrors(r'''
extension type A(required int it) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 8)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldModifier_static() {
    var parseResult = parseStringWithErrors(r'''
extension type A(static int it) {}
''');
    parseResult.assertErrors([error(diag.extraneousModifier, 17, 6)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_fieldName_asDeclaration() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int A) {}
''');
    parseResult.assertErrors([error(diag.memberWithClassName, 21, 1)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_formalParameterModifier_covariant_method_instance() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  void foo(covariant int a) {}
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifierInExtensionType, 38, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_formalParameterModifier_covariant_method_static() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  static void foo(covariant int a) {}
}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifierInExtensionType, 45, 9),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_multipleFields() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int a, String b) {}
''');
    parseResult.assertErrors([error(diag.multipleRepresentationFields, 22, 1)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_noField() {
    var parseResult = parseStringWithErrors(r'''
extension type A() {}
''');
    parseResult.assertErrors([error(diag.expectedRepresentationField, 17, 1)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_noFieldType() {
    var parseResult = parseStringWithErrors(r'''
extension type A(it) {}
''');
    parseResult.assertErrors([error(diag.expectedRepresentationType, 17, 2)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_noFieldType_var() {
    var parseResult = parseStringWithErrors(r'''
extension type A(var it) {}
''');
    parseResult.assertErrors([
      error(diag.expectedRepresentationType, 17, 3),
      error(diag.representationFieldModifier, 17, 3),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_superFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
extension type A(super.it) {}
''');
    parseResult.assertErrors([error(diag.expectedRepresentationField, 17, 5)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it,) {}
''');
    parseResult.assertErrors([
      error(diag.representationFieldTrailingComma, 23, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_error_typeParameters_afterConstructorName() {
    var parseResult = parseStringWithErrors(r'''
extension type A._<T>(T _) {}
''');
    parseResult.assertErrors([
      error(diag.expectedRepresentationField, 16, 0),
      error(diag.missingPrimaryConstructorParameters, 17, 1),
      error(diag.expectedExtensionTypeBody, 17, 1),
      error(diag.expectedExecutable, 18, 1),
      error(diag.missingConstFinalVarOrType, 19, 1),
      error(diag.expectedToken, 19, 1),
      error(diag.topLevelOperator, 20, 1),
    ]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_featureNotEnabled() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.1
class A {}
extension type B(int it) {}
class C {}
''');
    parseResult.assertErrors([error(diag.experimentNotEnabled, 36, 4)]);

    var node = parseResult.findNode.unit;
    assertParsedNodeText(node, r'''
CompilationUnit
  declarations
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: A
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
    ClassDeclaration
      classKeyword: class
      namePart: NameWithTypeParameters
        typeName: C
      body: BlockClassBody
        leftBracket: {
        rightBracket: }
''');
  }

  test_field_metadata() {
    var parseResult = parseStringWithErrors(r'''
extension type A(@foo int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_members_constructor() {
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
  primaryConstructor: PrimaryConstructorDeclaration
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
        typeName: SimpleIdentifier
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_const_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
extension type const A<T, U>.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_const_hasTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type const A<T, U>(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_const_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
extension type const A.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_const_noTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type const A(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_const_typeName_noFormalParameters() {
    var parseResult = parseStringWithErrors(r'''
extension type const E {}
''');
    parseResult.assertErrors([error(diag.missingPrimaryConstructor, 21, 1)]);

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
    var parseResult = parseStringWithErrors(r'''
extension type E {}
''');
    parseResult.assertErrors([error(diag.missingPrimaryConstructor, 15, 1)]);

    var node = parseResult.findNode.extensionTypeDeclaration('E');
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension @0
  typeKeyword: type @10
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_notConst_hasTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
extension type A<T, U>.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_notConst_hasTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A<T, U>(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_notConst_noTypeParameters_named() {
    var parseResult = parseStringWithErrors(r'''
extension type A.named(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructor_notConst_noTypeParameters_unnamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
  }

  test_primaryConstructorBody() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it) {
  this;
}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
      PrimaryConstructorBody
        thisKeyword: this
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''');
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
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: B
      NamedType
        name: C
  body: BlockClassBody
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
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
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
  }
}
