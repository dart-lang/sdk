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
    element2: #E0 T
    type: T
  name: p
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        declaredElement: <testLibraryFragment> T@14
          defaultType: null
      TypeParameter
        name: U
        declaredElement: <testLibraryFragment> U@17
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
      declaredElement: <testLibraryFragment> a@22
        element: isPublic
          type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: V
        element2: #E2 V
        type: V
      name: b
      declaredElement: <testLibraryFragment> b@27
        element: isPublic
          type: V
    rightParenthesis: )
  declaredElement: <testLibraryFragment> p@12
    element: isPublic
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
      declaredElement: <testLibraryFragment> a@18
        element: isPublic
          type: int
    rightParenthesis: )
  declaredElement: <testLibraryFragment> p@12
    element: isPublic
      type: void Function(int)
''');
  }
}
