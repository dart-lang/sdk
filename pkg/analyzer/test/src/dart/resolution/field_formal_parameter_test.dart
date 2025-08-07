// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldFormalParameterResolutionTest);
  });
}

@reflectiveTest
class FieldFormalParameterResolutionTest extends PubPackageResolutionTest {
  test_class_functionTyped() async {
    await assertNoErrorsInCode(r'''
class A {
  Function f;
  A(void this.f(int a));
}
''');

    var node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: void
    element2: <null>
    type: void
  thisKeyword: this
  period: .
  name: f
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredElement: <testLibraryFragment> a@44
        element: isPublic
          type: int
    rightParenthesis: )
  declaredElement: <testLibraryFragment> f@38
    element: isFinal isPublic
      type: void Function(int)
''');
  }

  /// There was a crash.
  /// https://github.com/dart-lang/sdk/issues/46968
  test_class_functionTyped_hasTypeParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  T Function<T>(T) f;
  A(U this.f<U>(U a));
}
''');

    var node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: U
    element2: #E0 U
    type: U
  thisKeyword: this
  period: .
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: U
        declaredElement: <testLibraryFragment> U@45
          defaultType: null
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element2: #E0 U
        type: U
      name: a
      declaredElement: <testLibraryFragment> a@50
        element: isPublic
          type: U
    rightParenthesis: )
  declaredElement: <testLibraryFragment> f@43
    element: isFinal isPublic
      type: U Function<U>(U)
''');
  }

  test_class_functionTyped_hasTypeParameters2() async {
    await assertNoErrorsInCode(r'''
class A<V> {
  T Function<T, U>(U, V) f;
  A(T this.f<T, U>(U a, V b));
}
''');

    var node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: T
    element2: #E0 T
    type: T
  thisKeyword: this
  period: .
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: <testLibraryFragment> T@54
          defaultType: null
      TypeParameter
        name: U
        declaredElement: <testLibraryFragment> U@57
          defaultType: null
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element2: #E1 U
        type: U
      name: a
      declaredElement: <testLibraryFragment> a@62
        element: isPublic
          type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: V
        element2: #E2 V
        type: V
      name: b
      declaredElement: <testLibraryFragment> b@67
        element: isPublic
          type: V
    rightParenthesis: )
  declaredElement: <testLibraryFragment> f@52
    element: isFinal isPublic
      type: T Function<T, U>(U, V)
''');
  }

  test_class_simple() async {
    await assertNoErrorsInCode(r'''
class A {
  int f;
  A(this.f);
}
''');

    var node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: f
  declaredElement: <testLibraryFragment> f@28
    element: hasImplicitType isFinal isPublic
      type: int
''');
  }

  test_class_simple_typed() async {
    await assertNoErrorsInCode(r'''
class A {
  int f;
  A(int this.f);
}
''');

    var node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  thisKeyword: this
  period: .
  name: f
  declaredElement: <testLibraryFragment> f@32
    element: isFinal isPublic
      type: int
''');
  }

  test_enum() async {
    await assertNoErrorsInCode(r'''
enum E {
  v(0);
  final int f;
  const E(this.f);
}
''');

    var node = findNode.fieldFormalParameter('this.f');
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: f
  declaredElement: <testLibraryFragment> f@47
    element: hasImplicitType isFinal isPublic
      type: int
''');
  }
}
