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
    name: SimpleIdentifier
      token: T
      staticElement: T@14
      staticType: null
    type: T
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: SimpleIdentifier
          token: U
          staticElement: U@17
          staticType: null
        type: U
      name: a
      declaredElement: self::@function::f::@parameter::p::@parameter::a
        type: U
    parameter: SimpleFormalParameter
      type: NamedType
        name: SimpleIdentifier
          token: V
          staticElement: V@7
          staticType: null
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
    name: SimpleIdentifier
      token: void
      staticElement: <null>
      staticType: null
    type: void
  name: p
  parameters: FormalParameterList
    leftParenthesis: (
    parameter: SimpleFormalParameter
      type: NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
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
