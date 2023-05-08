// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionTypedFormalParameterResolutionTest);
  });
}

@reflectiveTest
class FunctionTypedFormalParameterResolutionTest
    extends PubPackageResolutionTest {
  test_hasTypeParameters() async {
    await resolveTestCode('''
void f<V>(T p<T, U>(U a, V b)) {}
''');

    final node = findNode.singleFunctionTypedFormalParameter;
    assertResolvedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: T
    element: T@14
    type: T
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: U@17
        type: U
      name: a
      declaredElement: self::@function::f::@parameter::p::@parameter::a
        type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: V
        element: V@7
        type: V
      name: b
      declaredElement: self::@function::f::@parameter::p::@parameter::b
        type: V
    rightParenthesis: )
  declaredElement: self::@function::f::@parameter::p
    type: T Function<T, U>(U, V)
''');
  }

  test_simple() async {
    await resolveTestCode('''
void f(void p(int a)) {}
''');

    final node = findNode.singleFunctionTypedFormalParameter;
    assertResolvedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: void
    element: <null>
    type: void
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: a
      declaredElement: self::@function::f::@parameter::p::@parameter::a
        type: int
    rightParenthesis: )
  declaredElement: self::@function::f::@parameter::p
    type: void Function(int)
''');
  }
}
