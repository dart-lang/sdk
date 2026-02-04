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
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({int a = 0}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
extension type A([int a = 0]) {}
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
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_documentationComment_requiredNamed_final_functionTyped() {
    var parseResult = parseStringWithErrors(r'''
extension type A(
  /// aaa
  final int a(String x)
) {}
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
      parameter: FunctionTypedFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        keyword: final
        returnType: NamedType
          name: int
        name: a
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: SimpleFormalParameter
            type: NamedType
              name: String
            name: x
          rightParenthesis: )
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_documentationComment_requiredNamed_final_simple() {
    var parseResult = parseStringWithErrors(r'''
extension type A({
  /// aaa
  required final int a = 0,
}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          documentationComment: Comment
            tokens
              /// aaa
          requiredKeyword: required
          keyword: final
          type: NamedType
            name: int
          name: a
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_documentationComment_requiredPositional_final_simple() {
    var parseResult = parseStringWithErrors(r'''
extension type A(
  /// aaa
  final int a
) {}
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
        documentationComment: Comment
          tokens
            /// aaa
        keyword: final
        type: NamedType
          name: int
        name: a
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_fieldFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
extension type A(this.it) {}
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
      parameter: FieldFormalParameter
        thisKeyword: this
        period: .
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_functionTypedFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it()) {}
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
      parameter: FunctionTypedFormalParameter
        returnType: NamedType
          name: int
        name: it
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_const() {
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
        keyword: const
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant() {
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant int it) {}
''');
    parseResult.assertErrors([
      error(diag.invalidCovariantModifierInPrimaryConstructor, 17, 9),
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
        covariantKeyword: covariant
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_final() {
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant final int it) {}
''');
    parseResult.assertErrors([
      error(diag.invalidCovariantModifierInPrimaryConstructor, 17, 9),
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
        covariantKeyword: covariant
        keyword: final
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(covariant int it) {}
''');
    parseResult.assertErrors([
      error(diag.extraneousModifierInPrimaryConstructor, 33, 9),
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
        covariantKeyword: covariant
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_var() {
    var parseResult = parseStringWithErrors(r'''
extension type A(covariant var int it) {}
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
        covariantKeyword: covariant
        keyword: var
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_hasType() {
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
        keyword: final
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_hasType_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
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
        keyword: final
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType() {
    var parseResult = parseStringWithErrors(r'''
extension type A(final it) {}
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
        keyword: final
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(final it) {}
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
        keyword: final
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_required() {
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
        requiredKeyword: required
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_static() {
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

  test_primaryConstructor_formalParameters_keyword_var() {
    var parseResult = parseStringWithErrors(r'''
extension type A(var it) {}
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
        keyword: var
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_var_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(var it) {}
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
        keyword: var
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({int it = 0}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: it
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A({int it = 0}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: it
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({int? a, int? b}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A({int? a, int? b}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_requiredNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({int? a, required int b}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          type: NamedType
            name: int
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
extension type A([int it = 0]) {}
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
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: it
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A([int it = 0]) {}
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
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
          name: it
        separator: =
        defaultValue: IntegerLiteral
          literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
extension type A([int? a, int? b]) {}
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
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A([int? a, int? b]) {}
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
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({required int it}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          type: NamedType
            name: int
          name: it
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A({required int it}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          type: NamedType
            name: int
          name: it
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({required int a, int? b}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          type: NamedType
            name: int
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_requiredNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A({required int a, required int b}) {}
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
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          type: NamedType
            name: int
          name: a
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          requiredKeyword: required
          type: NamedType
            name: int
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional() {
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

  test_primaryConstructor_formalParameters_kind_requiredPositional_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
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

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalNamed() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int a, {int? b}) {}
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
        name: a
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalNamed_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(int a, {int? b}) {}
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
        name: a
      leftDelimiter: {
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalPositional() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int a, [int? b]) {}
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
        name: a
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalPositional_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(int a, [int? b]) {}
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
        name: a
      leftDelimiter: [
      parameter: DefaultFormalParameter
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            question: ?
          name: b
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_requiredPositional() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int a, int b) {}
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
        name: a
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: b
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_requiredPositional_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(int a, int b) {}
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
        name: a
      parameter: SimpleFormalParameter
        type: NamedType
          name: int
        name: b
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_memberWithClassName() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int A) {}
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
        name: A
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_metadata() {
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

  test_primaryConstructor_formalParameters_noFormalParameters() {
    var parseResult = parseStringWithErrors(r'''
extension type A() {}
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
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_noFormalParameters_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A() {}
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
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation() {
    var parseResult = parseStringWithErrors(r'''
extension type A(it) {}
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
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(it) {}
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
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_withMetadata() {
    var parseResult = parseStringWithErrors(r'''
extension type A(@foo it) {}
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
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_superFormalParameter() {
    var parseResult = parseStringWithErrors(r'''
extension type A(super.it) {}
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
      parameter: SuperFormalParameter
        superKeyword: super
        period: .
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_trailingComma() {
    var parseResult = parseStringWithErrors(r'''
extension type A(int it,) {}
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

  test_primaryConstructor_formalParameters_trailingComma_language310() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.10
extension type A(int it,) {}
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

  test_primaryConstructor_missing() {
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
