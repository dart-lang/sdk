// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeResolutionTest);
  });
}

@reflectiveTest
class ExtensionTypeResolutionTest extends PubPackageResolutionTest {
  test_constructor_named() async {
    await assertNoErrorsInCode(r'''
extension type A.named(int it) {}
''');

    final node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
      element: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldElement: self::@extensionType::A::@field::it
    constructorElement: self::@extensionType::A::@constructor::named
  leftBracket: {
  rightBracket: }
  declaredElement: self::@extensionType::A
''');
  }

  test_constructor_secondary_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  A.named(this.it);
}
''');

    final node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldElement: self::@extensionType::A::@field::it
    constructorElement: self::@extensionType::A::@constructor::new
  leftBracket: {
  members
    ConstructorDeclaration
      returnType: SimpleIdentifier
        token: A
        staticElement: self::@extensionType::A
        staticType: null
      period: .
      name: named
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: FieldFormalParameter
          thisKeyword: this
          period: .
          name: it
          declaredElement: self::@extensionType::A::@constructor::named::@parameter::it
            type: int
        rightParenthesis: )
      body: EmptyFunctionBody
        semicolon: ;
      declaredElement: self::@extensionType::A::@constructor::named
        type: A Function(int)
  rightBracket: }
  declaredElement: self::@extensionType::A
''');
  }

  test_constructor_secondary_fieldInitializer() async {
    await assertNoErrorsInCode(r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''');

    final node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: num
      element: dart:core::@class::num
      type: num
    fieldName: it
    rightParenthesis: )
    fieldElement: self::@extensionType::A::@field::it
    constructorElement: self::@extensionType::A::@constructor::new
  leftBracket: {
  members
    ConstructorDeclaration
      constKeyword: const
      returnType: SimpleIdentifier
        token: A
        staticElement: self::@extensionType::A
        staticType: null
      period: .
      name: named
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            element: dart:core::@class::int
            type: int
          name: a
          declaredElement: self::@extensionType::A::@constructor::named::@parameter::a
            type: int
        rightParenthesis: )
      separator: :
      initializers
        ConstructorFieldInitializer
          fieldName: SimpleIdentifier
            token: it
            staticElement: self::@extensionType::A::@field::it
            staticType: null
          equals: =
          expression: SimpleIdentifier
            token: a
            staticElement: self::@extensionType::A::@constructor::named::@parameter::a
            staticType: int
      body: EmptyFunctionBody
        semicolon: ;
      declaredElement: self::@extensionType::A::@constructor::named
        type: A Function(int)
  rightBracket: }
  declaredElement: self::@extensionType::A
''');
  }

  test_constructor_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {}
''');

    final node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldElement: self::@extensionType::A::@field::it
    constructorElement: self::@extensionType::A::@constructor::new
  leftBracket: {
  rightBracket: }
  declaredElement: self::@extensionType::A
''');
  }

  test_implementsClause() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) implements num {}
''');

    final node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldElement: self::@extensionType::A::@field::it
    constructorElement: self::@extensionType::A::@constructor::new
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: num
        element: dart:core::@class::num
        type: num
  leftBracket: {
  rightBracket: }
  declaredElement: self::@extensionType::A
''');
  }

  test_method_generic() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(int it) {
  void foo<U>(T t, U u) {
    T;
    U;
  }
}
''');

    final node = findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element: T@17
        type: T
      name: t
      declaredElement: self::@extensionType::A::@method::foo::@parameter::t
        type: T
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: U@41
        type: U
      name: u
      declaredElement: self::@extensionType::A::@method::foo::@parameter::u
        type: U
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: T
            staticElement: T@17
            staticType: Type
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: U
            staticElement: U@41
            staticType: Type
          semicolon: ;
      rightBracket: }
  declaredElement: self::@extensionType::A::@method::foo
    type: void Function<U>(T, U)
''');
  }

  test_typeParameters() async {
    await assertNoErrorsInCode(r'''
extension type A<T, U>(Map<T, U> it) {}
''');

    final node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: T@17
      TypeParameter
        name: U
        declaredElement: U@20
    rightBracket: >
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: Map
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: T
            element: T@17
            type: T
          NamedType
            name: U
            element: U@20
            type: U
        rightBracket: >
      element: dart:core::@class::Map
      type: Map<T, U>
    fieldName: it
    rightParenthesis: )
    fieldElement: self::@extensionType::A::@field::it
    constructorElement: self::@extensionType::A::@constructor::new
  leftBracket: {
  rightBracket: }
  declaredElement: self::@extensionType::A
''');
  }
}
