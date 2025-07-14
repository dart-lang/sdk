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

    var node = findNode.singleExtensionTypeDeclaration;
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
      element2: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> it@27
    constructorFragment: <testLibraryFragment> named@17
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment> A@15
''');
  }

  test_constructor_secondary_fieldFormalParameter() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  A.named(this.it);
}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> it@21
    constructorFragment: <testLibraryFragment> new@null
  leftBracket: {
  members
    ConstructorDeclaration
      returnType: SimpleIdentifier
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
          declaredElement: <testLibraryFragment> it@42
            element: hasImplicitType isFinal isPublic
              type: int
        rightParenthesis: )
      body: EmptyFunctionBody
        semicolon: ;
      declaredElement: <testLibraryFragment> named@31
        element: <testLibrary>::@extensionType::A::@constructor::named
          type: A Function(int)
  rightBracket: }
  declaredElement: <testLibraryFragment> A@15
''');
  }

  test_constructor_secondary_fieldInitializer() async {
    await assertNoErrorsInCode(r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: num
      element2: dart:core::@class::num
      type: num
    fieldName: it
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> it@21
    constructorFragment: <testLibraryFragment> new@null
  leftBracket: {
  members
    ConstructorDeclaration
      constKeyword: const
      returnType: SimpleIdentifier
        token: A
        element: <testLibrary>::@extensionType::A
        staticType: null
      period: .
      name: named
      parameters: FormalParameterList
        leftParenthesis: (
        parameter: SimpleFormalParameter
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredElement: <testLibraryFragment> a@47
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
      declaredElement: <testLibraryFragment> named@37
        element: <testLibrary>::@extensionType::A::@constructor::named
          type: A Function(int)
  rightBracket: }
  declaredElement: <testLibraryFragment> A@15
''');
  }

  test_constructor_unnamed() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> it@21
    constructorFragment: <testLibraryFragment> new@null
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment> A@15
''');
  }

  test_implementsClause() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) implements num {}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: A
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    fieldName: it
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> it@21
    constructorFragment: <testLibraryFragment> new@null
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: num
        element2: dart:core::@class::num
        type: num
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment> A@15
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

    var node = findNode.singleMethodDeclaration;
    assertResolvedNodeText(node, r'''
MethodDeclaration
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: foo
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: U
        declaredElement: <testLibraryFragment> U@41
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element2: #E0 T
        type: T
      name: t
      declaredElement: <testLibraryFragment> t@46
        element: isPublic
          type: T
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element2: #E1 U
        type: U
      name: u
      declaredElement: <testLibraryFragment> u@51
        element: isPublic
          type: U
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      statements
        ExpressionStatement
          expression: SimpleIdentifier
            token: T
            element: #E0 T
            staticType: Type
          semicolon: ;
        ExpressionStatement
          expression: SimpleIdentifier
            token: U
            element: #E1 U
            staticType: Type
          semicolon: ;
      rightBracket: }
  declaredElement: <testLibraryFragment> foo@37
    element: <testLibrary>::@extensionType::A::@method::foo
      type: void Function<U>(T, U)
''');
  }

  test_typeParameters() async {
    await assertNoErrorsInCode(r'''
extension type A<T, U>(Map<T, U> it) {}
''');

    var node = findNode.singleExtensionTypeDeclaration;
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
        declaredElement: <testLibraryFragment> T@17
          defaultType: dynamic
      TypeParameter
        name: U
        declaredElement: <testLibraryFragment> U@20
          defaultType: dynamic
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
            element2: #E0 T
            type: T
          NamedType
            name: U
            element2: #E1 U
            type: U
        rightBracket: >
      element2: dart:core::@class::Map
      type: Map<T, U>
    fieldName: it
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> it@33
    constructorFragment: <testLibraryFragment> new@null
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment> A@15
''');
  }

  test_typeParameters_wildcards() async {
    await assertNoErrorsInCode(r'''
extension type ET<_, _, _ extends num>(int _) {}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  name: ET
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: _
        declaredElement: <testLibraryFragment> _@18
          defaultType: dynamic
      TypeParameter
        name: _
        declaredElement: <testLibraryFragment> _@21
          defaultType: dynamic
      TypeParameter
        name: _
        extendsKeyword: extends
        bound: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        declaredElement: <testLibraryFragment> _@24
          defaultType: num
    rightBracket: >
  representation: RepresentationDeclaration
    leftParenthesis: (
    fieldType: NamedType
      name: int
      element2: dart:core::@class::int
      type: int
    fieldName: _
    rightParenthesis: )
    fieldFragment: <testLibraryFragment> _@43
    constructorFragment: <testLibraryFragment> new@null
  leftBracket: {
  rightBracket: }
  declaredElement: <testLibraryFragment> ET@15
''');
  }
}
