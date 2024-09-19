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
    element: T@14
    element2: <not-implemented>
    type: T
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: U
        element: U@17
        element2: <not-implemented>
        type: U
      name: a
      declaredElement: <testLibraryFragment>::@function::f::@parameter::p::@parameter::a
        type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: V
        element: V@7
        element2: <not-implemented>
        type: V
      name: b
      declaredElement: <testLibraryFragment>::@function::f::@parameter::p::@parameter::b
        type: V
    rightParenthesis: )
  declaredElement: <testLibraryFragment>::@function::f::@parameter::p
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
    element: <null>
    element2: <null>
    type: void
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      name: a
      declaredElement: <testLibraryFragment>::@function::f::@parameter::p::@parameter::a
        type: int
    rightParenthesis: )
  declaredElement: <testLibraryFragment>::@function::f::@parameter::p
    type: void Function(int)
''');
  }
}
