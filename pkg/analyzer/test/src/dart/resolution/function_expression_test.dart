// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionResolutionTest);
  });
}

@reflectiveTest
class FunctionExpressionResolutionTest extends PubPackageResolutionTest {
  test_genericFunctionExpression_fBoundedDefaultType() async {
    await assertNoErrorsInCode('''
void f() {
  <T extends List<T>>() {};
}
''');

    var node = findNode.functionExpression('<T extends');
    assertResolvedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        extendsKeyword: extends
        bound: NamedType
          name: List
          typeArguments: TypeArgumentList
            leftBracket: <
            arguments
              NamedType
                name: T
                element2: #E0 T
                type: T
            rightBracket: >
          element2: dart:core::@class::List
          type: List<T>
        declaredElement: <testLibraryFragment> T@14
          defaultType: List<dynamic>
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment> null@null
    element: null@null
      type: Null Function<T extends List<T>>()
  staticType: Null Function<T extends List<T>>()
''');
  }

  test_genericFunctionExpression_simpleDefaultType() async {
    await assertNoErrorsInCode('''
void f() {
  <T extends num>() {};
}
''');

    var node = findNode.functionExpression('<T extends');
    assertResolvedNodeText(node, r'''
FunctionExpression
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
        extendsKeyword: extends
        bound: NamedType
          name: num
          element2: dart:core::@class::num
          type: num
        declaredElement: <testLibraryFragment> T@14
          defaultType: num
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredElement: <testLibraryFragment> null@null
    element: null@null
      type: Null Function<T extends num>()
  staticType: Null Function<T extends num>()
''');
  }
}
