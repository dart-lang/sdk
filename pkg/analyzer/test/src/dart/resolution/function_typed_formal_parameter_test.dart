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

    var node = findNode.singleFunctionTypedFormalParameter;
    assertResolvedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: T
    element2: T@14
    type: T
  name: p
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: T@14
          defaultType: null
      TypeParameter
        name: U
        declaredElement: U@17
          defaultType: null
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element2: U@17
        type: U
      name: a
      declaredElement: <testLibraryFragment>::@function::f::@formalParameter::p::@formalParameter::a
        type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: V
        element2: V@7
        type: V
      name: b
      declaredElement: <testLibraryFragment>::@function::f::@formalParameter::p::@formalParameter::b
        type: V
    rightParenthesis: )
  declaredElement: <testLibraryFragment>::@function::f::@formalParameter::p
    type: T Function<T, U>(U, V)
''');
  }

  test_simple() async {
    await resolveTestCode('''
void f(void p(int a)) {}
''');

    var node = findNode.singleFunctionTypedFormalParameter;
    assertResolvedNodeText(node, r'''
FunctionTypedFormalParameter
  returnType: NamedType
    name: void
    element2: <null>
    type: void
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element2: dart:core::@class::int
        type: int
      name: a
      declaredElement: <testLibraryFragment>::@function::f::@formalParameter::p::@formalParameter::a
        type: int
    rightParenthesis: )
  declaredElement: <testLibraryFragment>::@function::f::@formalParameter::p
    type: void Function(int)
''');
  }
}
