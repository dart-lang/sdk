// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
  test_augment_implementsClause() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E implements I {}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: I
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''',
    );
  }

  test_augment_primaryConstructor() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type A(int it) {}
//                      ^
// [diag.extensionTypeAugmentationSpecifiesRepresentationField] An extension type augmentation can't specify a representation field.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it);
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: it
      rightParenthesis: )
  body: EmptyClassBody
    semicolon: ;
''');
  }

  test_constructor_factoryHead_named() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory named() => A(0);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  const factory named() = B;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory () => A(0);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  const factory () = B;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  new named() : this.it = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  const new named() : this.it = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  new () : this.it = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  const new () : this.it = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory A.named() => A(0);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory A() => A(0);
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.named() : this.it = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A() : this.it = 0;
}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo(covariant int a) {}
//         ^^^^^^^^^
// [diag.extraneousModifierInExtensionType] Can't have modifier 'covariant' in an extension type.
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static void foo(covariant int a) {}
//                ^^^^^^^^^
// [diag.extraneousModifierInExtensionType] Can't have modifier 'covariant' in an extension type.
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
          parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.1
class A {}
extension type B(int it) {}
//        ^^^^
// [diag.experimentNotEnabled] This requires the 'inline-class' language feature to be enabled.
class C {}
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.named(this.it);
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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

  test_members_constructor_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment E.named();
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      ConstructorDeclaration
        augmentKeyword: augment
        typeName: SimpleIdentifier
          token: E
        period: .
        name: named
        parameters: FormalParameterList
          leftParenthesis: (
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
    rightBracket: }
''',
    );
  }

  test_members_constructor_augment_factory_unnamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment factory E() => E(0);
}
''');

    var node = parseResult.findNode.singleConstructorDeclaration;
    assertParsedNodeText(node, r'''
ConstructorDeclaration
  augmentKeyword: augment
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: E
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: MethodInvocation
      methodName: SimpleIdentifier
        token: E
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
        rightParenthesis: )
    semicolon: ;
''');
  }

  test_members_field_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment int foo = 0;
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
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
''',
    );
  }

  test_members_field_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment static int foo = 0;
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        augmentKeyword: augment
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
''',
    );
  }

  test_members_field_instance() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  final int foo = 0;
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static int foo = 0;
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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

  test_members_getter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment int get foo => 0;
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
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
''',
    );
  }

  test_members_getter_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment static int get foo => 0;
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
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
''',
    );
  }

  test_members_method() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo() {}
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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

  test_members_method_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment void foo() {}
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
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
''',
    );
  }

  test_members_method_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment static void foo() {}
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
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
''',
    );
  }

  test_members_operator_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment int operator+(int other) => 0;
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        returnType: NamedType
          name: int
        operatorKeyword: operator
        name: +
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: other
          rightParenthesis: )
        body: ExpressionFunctionBody
          functionDefinition: =>
          expression: IntegerLiteral
            literal: 0
          semicolon: ;
    rightBracket: }
''',
    );
  }

  test_members_setter() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(int _) {}
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
          parameter: RegularFormalParameter
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

  test_members_setter_augment() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment set foo(int x) {}
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''',
    );
  }

  test_members_setter_augment_static() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
augment extension type E {
  augment static set foo(int x) {}
}
''');
    assertParsedNodeText(
      parseResult.findNode.singleExtensionTypeDeclaration,
      r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: E
  body: BlockClassBody
    leftBracket: {
    members
      MethodDeclaration
        augmentKeyword: augment
        modifierKeyword: static
        propertyKeyword: set
        name: foo
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
            name: x
          rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            rightBracket: }
    rightBracket: }
''',
    );
  }

  test_metadata() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
@foo
extension type A(int it) {}
''');

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
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type const A<T, U>.named(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type const A<T, U>(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type const A.named(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type const A(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type const E {}
//                   ^
// [diag.missingPrimaryConstructor] An extension type declaration must have a primary constructor declaration.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({int a = 0}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalPositional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A([int a = 0]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_documentationComment_requiredNamed_final_functionTyped() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(
  /// aaa
  final int a(String x)
) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
        functionTypedSuffix: FunctionTypedFormalParameterSuffix
          formalParameters: FormalParameterList
            leftParenthesis: (
            parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({
  /// aaa
  required final int a = 0,
}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        requiredKeyword: required
        constFinalOrVarKeyword: final
        type: NamedType
          name: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_documentationComment_requiredPositional_final_simple() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(
  /// aaa
  final int a
) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        documentationComment: Comment
          tokens
            /// aaa
        constFinalOrVarKeyword: final
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(this.it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it()) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: it
        functionTypedSuffix: FunctionTypedFormalParameterSuffix
          formalParameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_const() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(const int it) {}
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: const
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(covariant int it) {}
//               ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(covariant final int it) {}
//               ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        constFinalOrVarKeyword: final
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(covariant int it) {}
//               ^^^^^^^^^
// [diag.extraneousModifierInPrimaryConstructor] Can't have modifier 'covariant' in a primary constructor.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(covariant var int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        covariantKeyword: covariant
        constFinalOrVarKeyword: var
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(final int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(final int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(final it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(final it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: final
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_required() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(required int it) {}
//               ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'required' here.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(static int it) {}
//               ^^^^^^
// [diag.extraneousModifier] Can't have modifier 'static' here.
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(var it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_keyword_var_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(var it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        constFinalOrVarKeyword: var
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({int it = 0}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: it
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A({int it = 0}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: it
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: }
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({int? a, int? b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A({int? a, int? b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({int? a, required int b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A([int it = 0]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: it
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A([int it = 0]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: it
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
      rightDelimiter: ]
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A([int? a, int? b]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A([int? a, int? b]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: [
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({required int it}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A({required int it}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({required int a, int? b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        requiredKeyword: required
        type: NamedType
          name: int
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A({required int a, required int b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      leftDelimiter: {
      parameter: RegularFormalParameter
        requiredKeyword: required
        type: NamedType
          name: int
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int a, {int? b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
      leftDelimiter: {
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int a, {int? b}) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
      leftDelimiter: {
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int a, [int? b]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
      leftDelimiter: [
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int a, [int? b]) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
      leftDelimiter: [
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int a, int b) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int a, int b) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
        name: a
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int A) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(@foo int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A() {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A() {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_language310() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: it
      rightParenthesis: )
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_withMetadata() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(@foo it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(super.it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it,) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int it,) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type E {}
//             ^
// [diag.missingPrimaryConstructor] An extension type declaration must have a primary constructor declaration.
''');

    var node = parseResult.findNode.extensionTypeDeclaration('E');
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension @0
  typeKeyword: type @10
  namePart: PrimaryConstructorDeclaration
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A<T, U>.named(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A<T, U>(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A.named(int it) {}
''');

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
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) {
  this;
}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A(int it) implements B, C {}
''');

    var node = parseResult.findNode.singleExtensionTypeDeclaration;
    assertParsedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
    var parseResult = parseTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}
''');

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
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
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
