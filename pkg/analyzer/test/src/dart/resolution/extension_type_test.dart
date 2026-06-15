// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExtensionTypeResolutionTest extends PubPackageResolutionTest {
  test_augment_primaryConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

augment extension type A(int it) {}
//                      ^
// [diag.extensionTypeAugmentationSpecifiesRepresentationField] An extension type augmentation can't specify a representation field.
''');

    var node = result.findNode.extensionTypeDeclaration('augment');
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@58
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@52
''');
  }

  test_constructor_factoryHead_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory named() => A(0);
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@extensionType::A
          type: A
        element: <testLibrary>::@extensionType::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            staticType: int
        rightParenthesis: )
      staticType: A
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@37
    element: <testLibrary>::@extensionType::A::@constructor::named
      type: A Function()
''');
  }

  test_constructor_factoryHead_named_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type const A(int it) {
  const factory named(int it) = A;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: it
      declaredFragment: <testLibraryFragment> it@59
        element: isPublic
          type: int
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    element: <testLibrary>::@extensionType::A::@constructor::new
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@49
    element: <testLibrary>::@extensionType::A::@constructor::named
      type: A Function(int)
''');
  }

  test_constructor_factoryHead_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  factory () => A.named(0);
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@extensionType::A
          type: A
        period: .
        name: SimpleIdentifier
          token: named
          element: <testLibrary>::@extensionType::A::@constructor::named
          staticType: null
        element: <testLibrary>::@extensionType::A::@constructor::named
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
            staticType: int
        rightParenthesis: )
      staticType: A
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::A::@constructor::new
      type: A Function()
''');
  }

  test_constructor_factoryHead_unnamed_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type const A.named(int it) {
  const factory A(int it) = A.named;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  constKeyword: const
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: it
      declaredFragment: <testLibraryFragment> it@61
        element: isPublic
          type: int
    rightParenthesis: )
  separator: =
  redirectedConstructor: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::A::@constructor::new
      type: A Function(int)
''');
  }

  test_constructor_newHead_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  new named() : this.it = 0;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@extensionType::A::@field::it
        staticType: null
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@33
    element: <testLibrary>::@extensionType::A::@constructor::named
      type: A Function()
''');
  }

  test_constructor_newHead_named_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  const new named() : this.it = 0;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@extensionType::A::@field::it
        staticType: null
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@39
    element: <testLibrary>::@extensionType::A::@constructor::named
      type: A Function()
''');
  }

  test_constructor_newHead_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  new () : this.it = 0;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@extensionType::A::@field::it
        staticType: null
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::A::@constructor::new
      type: A Function()
''');
  }

  test_constructor_newHead_unnamed_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  const new () : this.it = 0;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
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
        element: <testLibrary>::@extensionType::A::@field::it
        staticType: null
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::A::@constructor::new
      type: A Function()
''');
  }

  test_constructor_typeName_factory_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  factory A.named() => A(0);
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
  period: .
  name: named
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@extensionType::A
          type: A
        element: <testLibrary>::@extensionType::A::@constructor::new
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
            staticType: int
        rightParenthesis: )
      staticType: A
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@39
    element: <testLibrary>::@extensionType::A::@constructor::named
      type: A Function()
''');
  }

  test_constructor_typeName_factory_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  factory A() => A.named(0);
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  factoryKeyword: factory
  typeName: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: ExpressionFunctionBody
    functionDefinition: =>
    expression: InstanceCreationExpression
      constructorName: ConstructorName
        type: NamedType
          name: A
          element: <testLibrary>::@extensionType::A
          type: A
        period: .
        name: SimpleIdentifier
          token: named
          element: <testLibrary>::@extensionType::A::@constructor::named
          staticType: null
        element: <testLibrary>::@extensionType::A::@constructor::named
      argumentList: ArgumentList
        leftParenthesis: (
        arguments
          IntegerLiteral
            literal: 0
            correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
            staticType: int
        rightParenthesis: )
      staticType: A
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::A::@constructor::new
      type: A Function()
''');
  }

  test_constructor_typeName_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.named() : this.it = 0;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
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
        element: <testLibrary>::@extensionType::A::@field::it
        staticType: null
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> named@31
    element: <testLibrary>::@extensionType::A::@constructor::named
      type: A Function()
''');
  }

  test_constructor_typeName_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  A() : this.it = 0;
}
''');

    var node = result.findNode.singleConstructorDeclaration;
    assertResolvedNodeText(node, r'''
ConstructorDeclaration
  typeName: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
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
        element: <testLibrary>::@extensionType::A::@field::it
        staticType: null
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::A::@constructor::new
      type: A Function()
''');
  }

  test_field_staticConst() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(String it) {
  static const int foo = 0;
  static const int bar = 1;
}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: String
          element: dart:core::@class::String
          type: String
        name: it
        declaredFragment: <testLibraryFragment> it@24
          element: isFinal isPublic
            type: String
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(String)
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: const
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          variables
            VariableDeclaration
              name: foo
              equals: =
              initializer: IntegerLiteral
                literal: 0
                staticType: int
              declaredFragment: <testLibraryFragment> foo@49
        semicolon: ;
        declaredFragment: <null>
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: const
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          variables
            VariableDeclaration
              name: bar
              equals: =
              initializer: IntegerLiteral
                literal: 1
                staticType: int
              declaredFragment: <testLibraryFragment> bar@77
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_implementsClause() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements num {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: num
        element: dart:core::@class::num
        type: num
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_method_generic() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {
  void foo<U>(T t, U u) {
    T;
    U;
  }
}
''');

    var node = result.findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: foo
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: U
        declaredFragment: <testLibraryFragment> U@41
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: T
        element: #E0 T
        type: T
      name: t
      declaredFragment: <testLibraryFragment> t@46
        element: isPublic
          type: T
    parameter: RegularFormalParameter
      type: NamedType
        name: U
        element: #E1 U
        type: U
      name: u
      declaredFragment: <testLibraryFragment> u@51
        element: isPublic
          type: U
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: TypeLiteral
            type: NamedType
              name: T
              element: #E0 T
              type: T
            staticType: Type
          semicolon: ;
        ExpressionStatement
          expression: TypeLiteral
            type: NamedType
              name: U
              element: #E1 U
              type: U
            staticType: Type
          semicolon: ;
      rightBracket: }
  declaredFragment: <testLibraryFragment> foo@37
    element: <testLibrary>::@extensionType::A::@method::foo
      type: void Function<U>(T, U)
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({int a = 0}) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
            staticType: int
        declaredFragment: <testLibraryFragment> a@22
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({int a})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_defaultValue_optionalPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A([int a = 0]) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: IntegerLiteral
            literal: 0
            staticType: int
        declaredFragment: <testLibraryFragment> a@22
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      rightDelimiter: ]
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function([int])
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_fieldFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(this.it) {}
//               ^^^^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@22
          element: hasImplicitType isFinal isPublic
            type: dynamic
            field: <null>
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(dynamic)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_fieldFormalParameter_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(this.it) {}
//               ^^^^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@38
          element: hasImplicitType isFinal isPublic
            type: dynamic
            field: <null>
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(dynamic)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_functionTypedFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it()) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        functionTypedSuffix: FunctionTypedFormalParameterSuffix
          formalParameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: int Function()
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int Function())
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_functionTypedFormalParameter_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int it()) {}
//               ^^^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        functionTypedSuffix: FunctionTypedFormalParameterSuffix
          formalParameters: FormalParameterList
            leftParenthesis: (
            rightParenthesis: )
        declaredFragment: <testLibraryFragment> it@37
          element: isFinal isPublic
            type: int Function()
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int Function())
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_keyword_const() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(const int it) {}
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@27
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_const_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(const int it) {}
//               ^^^^^
// [diag.extraneousModifier] Can't have modifier 'const' here.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@43
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(covariant int it) {}
//               ^^^^^^^^^
// [diag.invalidCovariantModifierInPrimaryConstructor] The 'covariant' modifier can only be used on non-final declaring parameters.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@31
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_covariant_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(covariant int it) {}
//               ^^^^^^^^^
// [diag.extraneousModifierInPrimaryConstructor] Can't have modifier 'covariant' in a primary constructor.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@47
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_hasType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(final int it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@27
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_hasType_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(final int it) {}
//               ^^^^^
// [diag.representationFieldModifier] Representation fields can't have the modifier 'var'.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@43
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(final it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@23
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_final_noType_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(final it) {}
//               ^^^^^
// [diag.representationFieldModifier] Representation fields can't have the modifier 'var'.
//                     ^^
// [diag.expectedRepresentationType] Expected a representation type.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@39
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_keyword_required() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(required int it) {}
//               ^^^^^^^^
// [diag.extraneousModifier] Can't have modifier 'required' here.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@30
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_static() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(static int it) {}
//               ^^^^^^
// [diag.extraneousModifier] Can't have modifier 'static' here.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@28
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_var() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(var it) {}
//               ^^^
// [diag.representationFieldModifier] Representation fields can't have the modifier 'var'.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@21
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_keyword_var_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(var it) {}
//               ^^^
// [diag.representationFieldModifier] Representation fields can't have the modifier 'var'.
//                   ^^
// [diag.expectedRepresentationType] Expected a representation type.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@37
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({int? it}) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: it
        declaredFragment: <testLibraryFragment> it@23
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({int? it})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A({int? it}) {}
//               ^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: it
        declaredFragment: <testLibraryFragment> it@39
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({int? it})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({int? a, int? b}) {}
//                      ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: a
        declaredFragment: <testLibraryFragment> a@23
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@31
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({int? a, int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_optionalNamed_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A({int? a, int? b}) {}
//                      ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: a
        declaredFragment: <testLibraryFragment> a@39
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@47
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({int? a, int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalNamed_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({int? a, required int b}) {}
//                      ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: a
        declaredFragment: <testLibraryFragment> a@23
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        requiredKeyword: required
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: b
        declaredFragment: <testLibraryFragment> b@39
          element: isPublic
            type: int
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({int? a, required int b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A([int? it]) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: it
        declaredFragment: <testLibraryFragment> it@23
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: ]
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function([int?])
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A([int? it]) {}
//               ^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: it
        declaredFragment: <testLibraryFragment> it@39
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: ]
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function([int?])
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A([int? a, int? b]) {}
//                      ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: a
        declaredFragment: <testLibraryFragment> a@23
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@31
          element: isPublic
            type: int?
      rightDelimiter: ]
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function([int?, int?])
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_optionalPositional_optionalPositional_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A([int? a, int? b]) {}
//                      ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int?
        name: a
        declaredFragment: <testLibraryFragment> a@39
          element: isFinal isPublic
            type: int?
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@47
          element: isPublic
            type: int?
      rightDelimiter: ]
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function([int?, int?])
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({required int it}) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@31
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({required int it})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A({required int it}) {}
//               ^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@47
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({required int it})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_optionalNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({required int a, int? b}) {}
//                              ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@31
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@39
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({required int a, int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredNamed_requiredNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({required int a, required int b}) {}
//                              ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@31
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        requiredKeyword: required
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: b
        declaredFragment: <testLibraryFragment> b@47
          element: isPublic
            type: int
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({required int a, required int b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int a, {int? b}) {}
//                    ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@30
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int, {int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalNamed_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int a, {int? b}) {}
//                    ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@46
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int, {int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int a, {int? b}) {}
//                    ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@30
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int, {int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_optionalPositional_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int a, {int? b}) {}
//                    ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      leftDelimiter: {
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          question: ?
          element: dart:core::@class::int
          type: int?
        name: b
        declaredFragment: <testLibraryFragment> b@46
          element: isPublic
            type: int?
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int, {int? b})
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_requiredPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int a, int b) {}
//                    ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: b
        declaredFragment: <testLibraryFragment> b@28
          element: isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int, int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_kind_requiredPositional_requiredPositional_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int a, int b) {}
//                    ^
// [diag.multipleRepresentationFields] Each extension type should have exactly one representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: <testLibraryFragment> a@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::a
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: b
        declaredFragment: <testLibraryFragment> b@44
          element: isPublic
            type: int
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int, int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_memberWithClassName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int A) {}
//                   ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: A
        declaredFragment: <testLibraryFragment> A@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::A
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_memberWithClassName_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int A) {}
//                   ^
// [diag.memberWithClassName] A class member can't have the same name as the enclosing class.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: A
        declaredFragment: <testLibraryFragment> A@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::A
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_metadata() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(@deprecated int it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
              token: deprecated
              element: dart:core::@getter::deprecated
              staticType: null
            element: dart:core::@getter::deprecated
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@33
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_noFormalParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A() {}
//               ^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.extensionTypeDeclaration('A');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function()
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_noFormalParameters_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A() {}
//               ^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function()
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: it
        declaredFragment: <testLibraryFragment> it@17
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(it) {}
//               ^^
// [diag.expectedRepresentationType] Expected a representation type.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        name: it
        declaredFragment: <testLibraryFragment> it@33
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_withMetadata() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(@deprecated it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
              token: deprecated
              element: dart:core::@getter::deprecated
              staticType: null
            element: dart:core::@getter::deprecated
        name: it
        declaredFragment: <testLibraryFragment> it@29
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_noTypeAnnotation_withMetadata_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(@deprecated it) {}
//                           ^^
// [diag.expectedRepresentationType] Expected a representation type.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
              token: deprecated
              element: dart:core::@getter::deprecated
              staticType: null
            element: dart:core::@getter::deprecated
        name: it
        declaredFragment: <testLibraryFragment> it@45
          element: hasImplicitType isFinal isPublic
            type: Object?
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(Object?)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_scope() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
//               ^^^
// [diag.notAType] int isn't a type.
  static const String int = 'not a type';
}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: <testLibrary>::@extensionType::A::@getter::int
          type: InvalidType
        name: it
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: InvalidType
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(InvalidType)
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: const
          type: NamedType
            name: String
            element: dart:core::@class::String
            type: String
          variables
            VariableDeclaration
              name: int
              equals: =
              initializer: SimpleStringLiteral
                literal: 'not a type'
              declaredFragment: <testLibraryFragment> int@49
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_scope_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int it) {
  static const String int = 'not a type';
}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    members
      FieldDeclaration
        staticKeyword: static
        fields: VariableDeclarationList
          keyword: const
          type: NamedType
            name: String
            element: dart:core::@class::String
            type: String
          variables
            VariableDeclaration
              name: int
              equals: =
              initializer: SimpleStringLiteral
                literal: 'not a type'
              declaredFragment: <testLibraryFragment> int@65
        semicolon: ;
        declaredFragment: <null>
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_superFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(super.it) {}
//               ^^^^^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@23
          element: hasImplicitType isFinal isPublic
            type: dynamic
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(dynamic)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_superFormalParameter_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(super.it) {}
//               ^^^^^
// [diag.expectedRepresentationField] Expected a representation field.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
        declaredFragment: <testLibraryFragment> it@39
          element: hasImplicitType isFinal isPublic
            type: dynamic
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(dynamic)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_formalParameters_trailingComma() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it,) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_formalParameters_trailingComma_language310() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type A(int it,) {}
//                     ^
// [diag.representationFieldTrailingComma] The representation field can't have a trailing comma.
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@37
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_primaryConstructor_missing() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E {}
//             ^
// [diag.missingPrimaryConstructor] An extension type declaration must have a primary constructor declaration.
//               ^
// [diag.expectedRepresentationField][column 18][length 0] Expected a representation field.
''');

    var node = result.findNode.extensionTypeDeclaration('extension type E');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: E
    formalParameters: FormalParameterList
      leftParenthesis: ( <synthetic>
      rightParenthesis: ) <synthetic>
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::E::@constructor::new
        type: E Function()
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> E@15
''');
  }

  test_primaryConstructor_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@27
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> named@17
      element: <testLibrary>::@extensionType::A::@constructor::named
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructor_scopes() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 0;
extension type E<@foo T>([@foo int it = foo]) {
  static const foo = 1;
}
''');

    var node = result.findNode.singlePrimaryConstructorDeclaration;
    assertResolvedNodeText(node, r'''
PrimaryConstructorDeclaration
  typeName: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        metadata
          Annotation
            atSign: @
            name: SimpleIdentifier
              token: foo
              element: <testLibrary>::@getter::foo
              staticType: null
            element: <testLibrary>::@getter::foo
        name: T
        declaredFragment: <testLibraryFragment> T@37
          defaultType: dynamic
    rightBracket: >
  formalParameters: FormalParameterList
    leftParenthesis: (
    leftDelimiter: [
    parameter: RegularFormalParameter
      metadata
        Annotation
          atSign: @
          name: SimpleIdentifier
            token: foo
            element: <testLibrary>::@extensionType::E::@getter::foo
            staticType: null
          element: <testLibrary>::@extensionType::E::@getter::foo
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: it
      defaultClause: FormalParameterDefaultClause
        separator: =
        value: SimpleIdentifier
          token: foo
          element: <testLibrary>::@extensionType::E::@getter::foo
          staticType: int
      declaredFragment: <testLibraryFragment> it@50
        element: isFinal isPublic
          type: int
          field: <testLibrary>::@extensionType::E::@field::it
    rightDelimiter: ]
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::E::@constructor::new
      type: E<T> Function([int])
''');
  }

  test_primaryConstructor_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type E<T extends U, U extends num>(T it) {}
''');

    var node = result.findNode.singlePrimaryConstructorDeclaration;
    assertResolvedNodeText(node, r'''
PrimaryConstructorDeclaration
  typeName: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        extendsKeyword: extends
        bound: NamedType
          name: U
          element: #E0 U
          type: U
        declaredFragment: <testLibraryFragment> T@17
          defaultType: num
      TypeParameter
        name: U
        extendsKeyword: extends
        bound: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        declaredFragment: <testLibraryFragment> U@30
          defaultType: num
    rightBracket: >
  formalParameters: FormalParameterList
    leftParenthesis: (
    parameter: RegularFormalParameter
      type: NamedType
        name: T
        element: #E1 T
        type: T
      name: it
      declaredFragment: <testLibraryFragment> it@47
        element: isFinal isPublic
          type: T
          field: <testLibrary>::@extensionType::E::@field::it
    rightParenthesis: )
  declaredFragment: <testLibraryFragment> new@null
    element: <testLibrary>::@extensionType::E::@constructor::new
      type: E<T, U> Function(T)
''');
  }

  test_primaryConstructorBody_duplicate() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({bool it = false}) {
  this : assert(it) {
    it;
  }
  this : assert(!it) {
//^^^^
// [diag.multiplePrimaryConstructorBodyDeclarations] Only one primary constructor body declaration is allowed.
    it;
  }
}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          name: bool
          element: dart:core::@class::bool
          type: bool
        name: it
        defaultClause: FormalParameterDefaultClause
          separator: =
          value: BooleanLiteral
            literal: false
            staticType: bool
        declaredFragment: <testLibraryFragment> it@23
          element: isFinal isPublic
            type: bool
            field: <testLibrary>::@extensionType::A::@field::it
      rightDelimiter: }
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function({bool it})
  body: BlockClassBody
    leftBracket: {
    members
      PrimaryConstructorBody
        thisKeyword: this
        colon: :
        initializers
          AssertInitializer
            assertKeyword: assert
            leftParenthesis: (
            condition: SimpleIdentifier
              token: it
              element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
              staticType: bool
            rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: it
                  element: <testLibrary>::@extensionType::A::@getter::it
                  staticType: bool
                semicolon: ;
            rightBracket: }
      PrimaryConstructorBody
        thisKeyword: this
        colon: :
        initializers
          AssertInitializer
            assertKeyword: assert
            leftParenthesis: (
            condition: PrefixExpression
              operator: !
              operand: SimpleIdentifier
                token: it
                element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
                staticType: bool
              element: <null>
              staticType: bool
            rightParenthesis: )
        body: BlockFunctionBody
          block: Block
            leftBracket: {
            statements
              ExpressionStatement
                expression: SimpleIdentifier
                  token: it
                  element: <testLibrary>::@extensionType::A::@getter::it
                  staticType: bool
                semicolon: ;
            rightBracket: }
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_primaryConstructorBody_metadata() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  @deprecated
  this;
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  metadata
    Annotation
      atSign: @
      name: SimpleIdentifier
        token: deprecated
        element: dart:core::@getter::deprecated
        staticType: null
      element: dart:core::@getter::deprecated
  thisKeyword: this
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_optionalNamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A({bool it = false}) {
  this : assert(it);
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: it
        element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryInitializerScope_requiredPositional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(bool it) {
  this : assert(it);
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  colon: :
  initializers
    AssertInitializer
      assertKeyword: assert
      leftParenthesis: (
      condition: SimpleIdentifier
        token: it
        element: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: bool
      rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
''');
  }

  test_primaryConstructorBody_primaryParameterScope() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  this {
    it;
    foo;
  }
  void foo() {}
}
''');

    var node = result.findNode.singlePrimaryConstructorBody;
    assertResolvedNodeText(node, r'''
PrimaryConstructorBody
  thisKeyword: this
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: it
            element: <testLibrary>::@extensionType::A::@getter::it
            staticType: int
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: foo
            element: <testLibrary>::@extensionType::A::@method::foo
            staticType: void Function()
          semicolon: ;
      rightBracket: }
''');
  }

  test_secondaryConstructor_fieldFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.named(this.it);
}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(int)
  body: BlockClassBody
    leftBracket: {
    members
      ConstructorDeclaration
        typeName: SimpleIdentifier
          token: A
          element: <testLibrary>::@extensionType::A
          staticType: null
        period: .
        name: named
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: FieldFormalParameter
            thisKeyword: this
            period: .
            name: it
            declaredFragment: <testLibraryFragment> it@42
              element: hasImplicitType isFinal isPublic
                type: int
                field: <testLibrary>::@extensionType::A::@field::it
          rightParenthesis: )
        body: EmptyFunctionBody
          semicolon: ;
        declaredFragment: <testLibraryFragment> named@31
          element: <testLibrary>::@extensionType::A::@constructor::named
            type: A Function(int)
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_secondaryConstructor_fieldInitializer() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        name: it
        declaredFragment: <testLibraryFragment> it@21
          element: isFinal isPublic
            type: num
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A Function(num)
  body: BlockClassBody
    leftBracket: {
    members
      ConstructorDeclaration
        constKeyword: const
        typeName: SimpleIdentifier
          token: A
          element: <testLibrary>::@extensionType::A
          staticType: null
        period: .
        name: named
        parameters: FormalParameterList
          leftParenthesis: (
          parameter: RegularFormalParameter
            type: NamedType
              name: int
              element: dart:core::@class::int
              type: int
            name: a
            declaredFragment: <testLibraryFragment> a@47
              element: isPublic
                type: int
          rightParenthesis: )
        separator: :
        initializers
          ConstructorFieldInitializer
            fieldName: SimpleIdentifier
              token: it
              element: <testLibrary>::@extensionType::A::@field::it
              staticType: null
            equals: =
            expression: SimpleIdentifier
              token: a
              element: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::a
              staticType: int
        body: EmptyFunctionBody
          semicolon: ;
        declaredFragment: <testLibraryFragment> named@37
          element: <testLibrary>::@extensionType::A::@constructor::named
            type: A Function(int)
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_typeParameter_bound_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<T extends Unresolved>(int it) {}
//                         ^^^^^^^^^^
// [diag.undefinedClass] Undefined class 'Unresolved'.
''');
  }

  test_typeParameter_metadata_undefined() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E<@Unresolved T>(int it) {}
//               ^^^^^^^^^^^
// [diag.undefinedAnnotation] Undefined name 'Unresolved' used as an annotation.
''');
  }

  test_typeParameters() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T, U>(Map<T, U> it) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
          declaredFragment: <testLibraryFragment> T@17
            defaultType: dynamic
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@20
            defaultType: dynamic
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: Map
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: T
                element: #E0 T
                type: T
              NamedType
                name: U
                element: #E1 U
                type: U
            rightBracket: >
          element: dart:core::@class::Map
          type: Map<T, U>
        name: it
        declaredFragment: <testLibraryFragment> it@33
          element: isFinal isPublic
            type: Map<T, U>
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A<T, U> Function(Map<T, U>)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@15
''');
  }

  test_typeParameters_wildcards() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type ET<_, _, _ extends num>(int _) {}
''');

    var node = result.findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  namePart: PrimaryConstructorDeclaration
    typeName: ET
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: _
          declaredFragment: <testLibraryFragment> _@18
            defaultType: dynamic
        TypeParameter
          name: _
          declaredFragment: <testLibraryFragment> _@21
            defaultType: dynamic
        TypeParameter
          name: _
          extendsKeyword: extends
          bound: NamedType
            name: num
            element: dart:core::@class::num
            type: num
          declaredFragment: <testLibraryFragment> _@24
            defaultType: num
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: _
        declaredFragment: <testLibraryFragment> _@43
          element: isFinal isPrivate
            type: int
            field: <testLibrary>::@extensionType::ET::@field::_
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::ET::@constructor::new
        type: ET<_, _, _> Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> ET@15
''');
  }
}
