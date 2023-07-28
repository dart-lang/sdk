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
  test_constructor_implementsClause() async {
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
