// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationTypeParameterCountTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationTypeParameterCountTest extends PubPackageResolutionTest {
  test_class_0_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
augment class A<T> {}
//              ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.classDeclaration('augment class A');
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
          declaredFragment: <testLibraryFragment> T@27
            defaultType: null
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@25
''');
  }

  test_class_1_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
augment class A {}
//            ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.classDeclaration('augment class A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
augment class A<T> {}
''');
    var node = result.findNode.classDeclaration('augment class A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
augment class A<T, U> {}
//                 ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.

void f(A<int> a) {}
''');
    var node = result.findNode.classDeclaration('augment class A');
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
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@33
            defaultType: null
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_class_1_3() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
augment class A<T, U, V> {}
//                 ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.classDeclaration('augment class A');
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
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@33
            defaultType: null
        TypeParameter
          name: V
          declaredFragment: <testLibraryFragment> V@36
            defaultType: null
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_class_2_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {}
augment class A<T> {}
//               ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.classDeclaration('augment class A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo() {}
}
augment class A {
  augment void foo<T>();
//                 ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
}
''');
    var node = result.findNode.methodDeclaration('augment void foo');
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
        declaredFragment: <testLibraryFragment> T@65
          defaultType: null
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: EmptyFunctionBody
    semicolon: ;
  declaredFragment: <testLibraryFragment> foo@61
    element: <testLibrary>::@class::A::@method::foo
      type: void Function()
''');
  }

  test_class_method_1_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T>() {}
}
augment class A {
  augment void foo<T>();
}
''');
    var node = result.findNode.methodDeclaration('augment void foo');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T>() {}
}
augment class A {
  augment void foo<T, U>();
//                    ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
}

void f(A a) {
  a.foo<int>();
}
''');
    var node = result.findNode.methodDeclaration('augment void foo');
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
      TypeParameter
        name: U
        declaredFragment: <testLibraryFragment> U@71
          defaultType: null
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

  test_class_method_2_1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  void foo<T, U>() {}
}
augment class A {
  augment void foo<T>();
//                  ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
}
''');
  }

  test_class_staticMethod_0_1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
augment class A {
  augment static void foo<T>();
//                        ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
}
''');
  }

  test_class_staticMethod_1_2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo<T>() {}
}
augment class A {
  augment static void foo<T, U>();
//                           ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
}

void f() {
  A.foo<int>();
}
''');
  }

  test_class_staticMethod_2_1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo<T, U>() {}
}
augment class A {
  augment static void foo<T>();
//                         ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
}
''');
  }

  test_enum_0_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum A {v}
augment enum A<T> {}
//             ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.enumDeclaration('augment enum A');
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
          declaredFragment: <testLibraryFragment> T@26
            defaultType: null
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@24
''');
  }

  test_enum_1_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum A<T> {v}
augment enum A {}
//           ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.enumDeclaration('augment enum A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
enum A<T> {v}
augment enum A <T>{}
''');
    var node = result.findNode.enumDeclaration('augment enum A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
enum A<T> {v}
augment enum A<T, U> {}
//                ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.enumDeclaration('augment enum A');
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
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@32
            defaultType: null
      rightBracket: >
  body: BlockEnumBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@27
''');
  }

  test_enum_2_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum A<T, U> {v}
augment enum A<T> {}
//              ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.enumDeclaration('augment enum A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A on int {}
augment extension A<T> {}
//                  ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionDeclaration('augment extension A');
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
        declaredFragment: <testLibraryFragment> T@42
          defaultType: null
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@40
''');
  }

  test_extension_1_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A<T> on int {}
augment extension A {}
//                ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionDeclaration('augment extension A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A<T> on int {}
augment extension A<T> {}
''');
    var node = result.findNode.extensionDeclaration('augment extension A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A<T> on int {}
augment extension A<T, U> {}
//                     ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionDeclaration('augment extension A');
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
      TypeParameter
        name: U
        declaredFragment: <testLibraryFragment> U@48
          defaultType: null
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@43
''');
  }

  test_extension_2_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension A<T, U> on int {}
augment extension A<T> {}
//                   ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionDeclaration('augment extension A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}
augment extension type A<T> {}
//                       ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionTypeDeclaration(
      'augment extension type A',
    );
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@53
            defaultType: null
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@51
''');
  }

  test_extensionType_1_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}
augment extension type A {}
//                     ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionTypeDeclaration(
      'augment extension type A',
    );
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: A
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@54
''');
  }

  test_extensionType_1_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}
augment extension type A<T> {}
''');
    var node = result.findNode.extensionTypeDeclaration(
      'augment extension type A',
    );
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@56
            defaultType: dynamic
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@54
''');
  }

  test_extensionType_1_2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(int it) {}
augment extension type A<T, U> {}
//                          ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionTypeDeclaration(
      'augment extension type A',
    );
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@56
            defaultType: dynamic
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@59
            defaultType: null
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@54
''');
  }

  test_extensionType_2_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T, U>(int it) {}
augment extension type A<T> {}
//                        ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.extensionTypeDeclaration(
      'augment extension type A',
    );
    assertResolvedNodeText(node, r'''
ExtensionTypeDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeKeyword: type
  namePart: NameWithTypeParameters
    typeName: A
    typeParameters: TypeParameterList
      leftBracket: <
      typeParameters
        TypeParameter
          name: T
          declaredFragment: <testLibraryFragment> T@59
            defaultType: dynamic
      rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@57
''');
  }

  test_mixin_0_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A {}
augment mixin A<T> {}
//              ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.mixinDeclaration('augment mixin A');
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
        declaredFragment: <testLibraryFragment> T@27
          defaultType: null
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@25
''');
  }

  test_mixin_1_0() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {}
augment mixin A {}
//            ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.mixinDeclaration('augment mixin A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {}
augment mixin A<T> {}
''');
    var node = result.findNode.mixinDeclaration('augment mixin A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A<T> {}
augment mixin A<T, U> {}
//                 ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.mixinDeclaration('augment mixin A');
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
      TypeParameter
        name: U
        declaredFragment: <testLibraryFragment> U@33
          defaultType: null
    rightBracket: >
  body: BlockClassBody
    leftBracket: {
    rightBracket: }
  declaredFragment: <testLibraryFragment> A@28
''');
  }

  test_mixin_2_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin A<T, U> {}
augment mixin A<T> {}
//               ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.mixinDeclaration('augment mixin A');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {}
augment void f<T>();
//             ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
    var node = result.findNode.functionDeclaration('augment void f');
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
          declaredFragment: <testLibraryFragment> T@27
            defaultType: null
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
    declaredFragment: <testLibraryFragment> f@25
      element: <testLibrary>::@function::f
        type: void Function()
    staticType: void Function()
  declaredFragment: <testLibraryFragment> f@25
    element: <testLibrary>::@function::f
      type: void Function()
''');
  }

  test_topLevelFunction_1_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>() {}
augment void f<T>();
''');
    var node = result.findNode.functionDeclaration('augment void f');
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
    body: EmptyFunctionBody
      semicolon: ;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f<T>() {}
augment void f<T, U>();
//                ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.

void g() {
  f<int>();
}
''');
    var node = result.findNode.functionDeclaration('augment void f');
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
        TypeParameter
          name: U
          declaredFragment: <testLibraryFragment> U@33
            defaultType: null
      rightBracket: >
    parameters: FormalParameterList
      leftParenthesis: (
      rightParenthesis: )
    body: EmptyFunctionBody
      semicolon: ;
    declaredFragment: <testLibraryFragment> f@28
      element: <testLibrary>::@function::f
        type: void Function<T>()
    staticType: void Function<T>()
  declaredFragment: <testLibraryFragment> f@28
    element: <testLibrary>::@function::f
      type: void Function<T>()
''');
  }

  test_topLevelFunction_2_1() async {
    await resolveTestCodeWithDiagnostics(r'''
void f<T, U>() {}
augment void f<T>();
//              ^
// [diag.augmentationTypeParameterCount] The augmentation must have the same number of type parameters as the declaration.
''');
  }
}
