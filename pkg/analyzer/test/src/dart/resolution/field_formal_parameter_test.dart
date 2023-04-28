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

    final node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: void
    element: <null>
    type: void
  thisKeyword: this
  period: .
  name: f
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: a
      declaredElement: self::@class::A::@constructor::new::@parameter::f::@parameter::a
        type: int
    rightParenthesis: )
  declaredElement: self::@class::A::@constructor::new::@parameter::f
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

    final node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: U
    element: U@45
    type: U
  thisKeyword: this
  period: .
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: U
        declaredElement: U@45
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: U@45
        type: U
      name: a
      declaredElement: self::@class::A::@constructor::new::@parameter::f::@parameter::a
        type: U
    rightParenthesis: )
  declaredElement: self::@class::A::@constructor::new::@parameter::f
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

    final node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: T
    element: T@54
    type: T
  thisKeyword: this
  period: .
  name: f
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: T@54
      TypeParameter
        name: U
        declaredElement: U@57
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: U@57
        type: U
      name: a
      declaredElement: self::@class::A::@constructor::new::@parameter::f::@parameter::a
        type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: V
        element: V@8
        type: V
      name: b
      declaredElement: self::@class::A::@constructor::new::@parameter::f::@parameter::b
        type: V
    rightParenthesis: )
  declaredElement: self::@class::A::@constructor::new::@parameter::f
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

    final node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: f
  declaredElement: self::@class::A::@constructor::new::@parameter::f
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

    final node = findNode.singleFieldFormalParameter;
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  type: NamedType
    name: int
    element: dart:core::@class::int
    type: int
  thisKeyword: this
  period: .
  name: f
  declaredElement: self::@class::A::@constructor::new::@parameter::f
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

    final node = findNode.fieldFormalParameter('this.f');
    assertResolvedNodeText(node, r'''
FieldFormalParameter
  thisKeyword: this
  period: .
  name: f
  declaredElement: self::@enum::E::@constructor::new::@parameter::f
    type: int
''');
  }
}
