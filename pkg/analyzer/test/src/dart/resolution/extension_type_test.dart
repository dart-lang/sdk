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
  test_constructor_formalParameter_metadata() async {
    var code = r'''
extension type A(@deprecated int it) {}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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

  test_constructor_named() async {
    var code = r'''
extension type A.named(int it) {}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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

  test_constructor_secondary_fieldFormalParameter() async {
    var code = r'''
extension type A(int it) {
  A.named(this.it);
}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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

  test_constructor_secondary_fieldInitializer() async {
    var code = r'''
extension type A(num it) {
  const A.named(int a) : it = a;
}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
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
          parameter: SimpleFormalParameter
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

  test_constructor_unnamed() async {
    var code = r'''
extension type A(int it) {}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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

  test_field_staticConst() async {
    var code = r'''
extension type A(String it) {
  static const int foo = 0;
  static const int bar = 1;
}
''';

    await assertNoErrorsInCode(code);

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: SimpleFormalParameter
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
    await assertNoErrorsInCode(r'''
extension type A(int it) implements num {}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
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
    parameter: SimpleFormalParameter
      type: NamedType
        name: T
        element: #E0 T
        type: T
      name: t
      declaredFragment: <testLibraryFragment> t@46
        element: isPublic
          type: T
    parameter: SimpleFormalParameter
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
  declaredFragment: <testLibraryFragment> foo@37
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
  primaryConstructor: PrimaryConstructorDeclaration
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
      parameter: SimpleFormalParameter
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
    await assertNoErrorsInCode(r'''
extension type ET<_, _, _ extends num>(int _) {}
''');

    var node = findNode.singleExtensionTypeDeclaration;
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
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
      parameter: SimpleFormalParameter
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
