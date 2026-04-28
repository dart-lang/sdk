// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterCountTest);
  });
}

@reflectiveTest
class AugmentationTypeParameterCountTest extends PubPackageResolutionTest {
  test_class_0_1() async {
    await assertErrorsInCode(
      r'''
class A {}
augment class A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 26, 1)],
    );
    var node = findNode.classDeclaration('augment class A');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@25
invalidNodes
  TypeParameterListImpl [26, 29)
''');
  }

  test_class_1_0() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A {}
''',
      [error(diag.augmentationTypeParameterCount, 29, 1)],
    );
    var node = findNode.classDeclaration('augment class A');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_class_1_1() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
augment class A<T> {}
''');
    var node = findNode.classDeclaration('augment class A');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@30
            defaultType: dynamic
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_class_1_2() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A<T, U> {}
''',
      [error(diag.augmentationTypeParameterCount, 29, 1)],
    );
    var node = findNode.classDeclaration('augment class A');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@30
            defaultType: dynamic
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
invalidNodes
  TypeParameterImpl [33, 34)
''');
  }

  test_class_1_3() async {
    await assertErrorsInCode(
      r'''
class A<T> {}
augment class A<T, U, V> {}
''',
      [error(diag.augmentationTypeParameterCount, 29, 1)],
    );
    var node = findNode.classDeclaration('augment class A');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@30
            defaultType: dynamic
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
invalidNodes
  TypeParameterImpl [33, 34)
  TypeParameterImpl [36, 37)
''');
  }

  test_class_2_1() async {
    await assertErrorsInCode(
      r'''
class A<T, U> {}
augment class A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 32, 1)],
    );
    var node = findNode.classDeclaration('augment class A');
    assertResolvedNodeText(node, r'''
ClassDeclaration
  augmentKeyword: augment
  classKeyword: class
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@33
            defaultType: dynamic
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_class_method_0_1() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo() {}
}
augment class A {
  augment void foo<T>();
}
''',
      [error(diag.augmentationTypeParameterCount, 64, 1)],
    );
    var node = findNode.methodDeclaration('augment void foo');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: foo
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> foo@61
    element: <testLibrary>::@class::A::@method::foo
      type: void Function()
invalidNodes
  TypeParameterListImpl [64, 67)
''');
  }

  test_class_method_1_1() async {
    await assertNoErrorsInCode(r'''
class A {
  void foo<T>() {}
}
augment class A {
  augment void foo<T>();
}
''');
    var node = findNode.methodDeclaration('augment void foo');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: foo
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@68
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> foo@64
    element: <testLibrary>::@class::A::@method::foo
      type: void Function<T>()
''');
  }

  test_class_method_1_2() async {
    await assertErrorsInCode(
      r'''
class A {
  void foo<T>() {}
}
augment class A {
  augment void foo<T, U>();
}
''',
      [error(diag.augmentationTypeParameterCount, 67, 1)],
    );
    var node = findNode.methodDeclaration('augment void foo');
    assertResolvedNodeText(node, r'''
MethodDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: foo
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@68
          defaultType: dynamic
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> foo@64
    element: <testLibrary>::@class::A::@method::foo
      type: void Function<T>()
invalidNodes
  TypeParameterImpl [71, 72)
''');
  }

  test_enum_0_1() async {
    await assertErrorsInCode(
      r'''
enum A {v}
augment enum A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 25, 1)],
    );
    var node = findNode.enumDeclaration('augment enum A');
    assertResolvedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@24
invalidNodes
  TypeParameterListImpl [25, 28)
''');
  }

  test_enum_1_0() async {
    await assertErrorsInCode(
      r'''
enum A<T> {v}
augment enum A {}
''',
      [error(diag.augmentationTypeParameterCount, 28, 1)],
    );
    var node = findNode.enumDeclaration('augment enum A');
    assertResolvedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@27
''');
  }

  test_enum_1_1() async {
    await assertNoErrorsInCode(r'''
enum A<T> {v}
augment enum A <T>{}
''');
    var node = findNode.enumDeclaration('augment enum A');
    assertResolvedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@30
            defaultType: dynamic
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@27
''');
  }

  test_enum_1_2() async {
    await assertErrorsInCode(
      r'''
enum A<T> {v}
augment enum A<T, U> {}
''',
      [error(diag.augmentationTypeParameterCount, 28, 1)],
    );
    var node = findNode.enumDeclaration('augment enum A');
    assertResolvedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@29
            defaultType: dynamic
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@27
invalidNodes
  TypeParameterImpl [32, 33)
''');
  }

  test_enum_2_1() async {
    await assertErrorsInCode(
      r'''
enum A<T, U> {v}
augment enum A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 31, 1)],
    );
    var node = findNode.enumDeclaration('augment enum A');
    assertResolvedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@32
            defaultType: dynamic
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@30
''');
  }

  test_extension_0_1() async {
    await assertErrorsInCode(
      r'''
extension A on int {}
augment extension A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 41, 1)],
    );
    var node = findNode.extensionDeclaration('augment extension A');
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@40
invalidNodes
  TypeParameterListImpl [41, 44)
''');
  }

  test_extension_1_0() async {
    await assertErrorsInCode(
      r'''
extension A<T> on int {}
augment extension A {}
''',
      [error(diag.augmentationTypeParameterCount, 44, 1)],
    );
    var node = findNode.extensionDeclaration('augment extension A');
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@43
''');
  }

  test_extension_1_1() async {
    await assertNoErrorsInCode(r'''
extension A<T> on int {}
augment extension A<T> {}
''');
    var node = findNode.extensionDeclaration('augment extension A');
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@45
          defaultType: dynamic
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@43
''');
  }

  test_extension_1_2() async {
    await assertErrorsInCode(
      r'''
extension A<T> on int {}
augment extension A<T, U> {}
''',
      [error(diag.augmentationTypeParameterCount, 44, 1)],
    );
    var node = findNode.extensionDeclaration('augment extension A');
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@45
          defaultType: dynamic
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@43
invalidNodes
  TypeParameterImpl [48, 49)
''');
  }

  test_extension_2_1() async {
    await assertErrorsInCode(
      r'''
extension A<T, U> on int {}
augment extension A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 47, 1)],
    );
    var node = findNode.extensionDeclaration('augment extension A');
    assertResolvedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@48
          defaultType: dynamic
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@46
''');
  }

  test_extensionType_0_1() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {}
augment extension type A<T>(int it) {}
''',
      [error(diag.augmentationTypeParameterCount, 52, 1)],
    );
    var node = findNode.extensionTypeDeclaration('augment extension type A');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@60
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
  declaredFragment: <testLibraryFragment> A@51
invalidNodes
  TypeParameterListImpl [52, 55)
''');
  }

  test_extensionType_1_0() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}
augment extension type A(int it) {}
''',
      [error(diag.augmentationTypeParameterCount, 55, 1)],
    );
    var node = findNode.extensionTypeDeclaration('augment extension type A');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@60
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A<T> Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@54
''');
  }

  test_extensionType_1_1() async {
    await assertNoErrorsInCode(r'''
extension type A<T>(int it) {}
augment extension type A<T>(int it) {}
''');
    var node = findNode.extensionTypeDeclaration('augment extension type A');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@56
            defaultType: dynamic
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@63
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A<T> Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@54
''');
  }

  test_extensionType_1_2() async {
    await assertErrorsInCode(
      r'''
extension type A<T>(int it) {}
augment extension type A<T, U>(int it) {}
''',
      [error(diag.augmentationTypeParameterCount, 55, 1)],
    );
    var node = findNode.extensionTypeDeclaration('augment extension type A');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@56
            defaultType: dynamic
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@66
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A<T> Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@54
invalidNodes
  TypeParameterImpl [59, 60)
''');
  }

  test_extensionType_2_1() async {
    await assertErrorsInCode(
      r'''
extension type A<T, U>(int it) {}
augment extension type A<T>(int it) {}
''',
      [error(diag.augmentationTypeParameterCount, 58, 1)],
    );
    var node = findNode.extensionTypeDeclaration('augment extension type A');
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  primaryConstructor: PrimaryConstructorDeclaration
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@59
            defaultType: dynamic
      rightBracket: >
    formalParameters: FormalParameterList
      leftParenthesis: (
      parameter: RegularFormalParameter
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: it
        declaredFragment: <testLibraryFragment> it@66
          element: isFinal isPublic
            type: int
            field: <testLibrary>::@extensionType::A::@field::it
      rightParenthesis: )
    declaredFragment: <testLibraryFragment> new@null
      element: <testLibrary>::@extensionType::A::@constructor::new
        type: A<T, U> Function(int)
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@57
''');
  }

  test_mixin_0_1() async {
    await assertErrorsInCode(
      r'''
mixin A {}
augment mixin A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 26, 1)],
    );
    var node = findNode.mixinDeclaration('augment mixin A');
    assertResolvedNodeText(node, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@25
invalidNodes
  TypeParameterListImpl [26, 29)
''');
  }

  test_mixin_1_0() async {
    await assertErrorsInCode(
      r'''
mixin A<T> {}
augment mixin A {}
''',
      [error(diag.augmentationTypeParameterCount, 29, 1)],
    );
    var node = findNode.mixinDeclaration('augment mixin A');
    assertResolvedNodeText(node, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_mixin_1_1() async {
    await assertNoErrorsInCode(r'''
mixin A<T> {}
augment mixin A<T> {}
''');
    var node = findNode.mixinDeclaration('augment mixin A');
    assertResolvedNodeText(node, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@30
          defaultType: dynamic
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_mixin_1_2() async {
    await assertErrorsInCode(
      r'''
mixin A<T> {}
augment mixin A<T, U> {}
''',
      [error(diag.augmentationTypeParameterCount, 29, 1)],
    );
    var node = findNode.mixinDeclaration('augment mixin A');
    assertResolvedNodeText(node, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@30
          defaultType: dynamic
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
invalidNodes
  TypeParameterImpl [33, 34)
''');
  }

  test_mixin_2_1() async {
    await assertErrorsInCode(
      r'''
mixin A<T, U> {}
augment mixin A<T> {}
''',
      [error(diag.augmentationTypeParameterCount, 32, 1)],
    );
    var node = findNode.mixinDeclaration('augment mixin A');
    assertResolvedNodeText(node, r'''
MixinDeclaration
  augmentKeyword: augment
  mixinKeyword: mixin
  name: A
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredFragment: <testLibraryFragment> T@33
          defaultType: dynamic
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@31
''');
  }

  test_topLevelFunction_0_1() async {
    await assertErrorsInCode(
      r'''
void f() {}
augment void f<T>() {}
''',
      [error(diag.augmentationTypeParameterCount, 26, 1)],
    );
    var node = findNode.functionDeclaration('augment void f');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: f
  functionExpression: FunctionExpression
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> f@25
      element: <testLibrary>::@function::f
        type: void Function()
    staticType: void Function()
  declaredFragment: <testLibraryFragment> f@25
    element: <testLibrary>::@function::f
      type: void Function()
invalidNodes
  TypeParameterListImpl [26, 29)
''');
  }

  test_topLevelFunction_1_1() async {
    await assertNoErrorsInCode(r'''
void f<T>() {}
augment void f<T>() {}
''');
    var node = findNode.functionDeclaration('augment void f');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: f
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@30
            defaultType: dynamic
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> f@28
      element: <testLibrary>::@function::f
        type: void Function<T>()
    staticType: void Function<T>()
  declaredFragment: <testLibraryFragment> f@28
    element: <testLibrary>::@function::f
      type: void Function<T>()
''');
  }

  test_topLevelFunction_1_2() async {
    await assertErrorsInCode(
      r'''
void f<T>() {}
augment void f<T, U>() {}
''',
      [error(diag.augmentationTypeParameterCount, 29, 1)],
    );
    var node = findNode.functionDeclaration('augment void f');
    assertResolvedNodeText(node, r'''
FunctionDeclaration
  augmentKeyword: augment
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: f
  functionExpression: FunctionExpression
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@30
            defaultType: dynamic
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: BlockFunctionBody
      block: Block
        leftBracket: {
        rightBracket: }
    declaredFragment: <testLibraryFragment> f@28
      element: <testLibrary>::@function::f
        type: void Function<T>()
    staticType: void Function<T>()
  declaredFragment: <testLibraryFragment> f@28
    element: <testLibrary>::@function::f
      type: void Function<T>()
invalidNodes
  TypeParameterImpl [33, 34)
''');
  }
}
