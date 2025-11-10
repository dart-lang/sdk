// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
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
                element: #E0 T
                type: T
            rightBracket: >
          element: dart:core::@class::List
          type: List<T>
        declaredFragment: <testLibraryFragment> T@14
          defaultType: List<dynamic>
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> null@null
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
          element: dart:core::@class::num
          type: num
        declaredFragment: <testLibraryFragment> T@14
          defaultType: num
    rightBracket: >
  parameters: FormalParameterList
    leftParenthesis: (
    rightParenthesis: )
  body: BlockFunctionBody
    block: Block
      leftBracket: {
      rightBracket: }
  declaredFragment: <testLibraryFragment> null@null
    element: null@null
      type: Null Function<T extends num>()
  staticType: Null Function<T extends num>()
''');
  }

  test_signatureScope_noFormalParameters() async {
    await assertErrorsInCode(
      '''
var f = ({int x = x}) {};
''',
      [error(CompileTimeErrorCode.undefinedIdentifier, 18, 1)],
    );

    var node = findNode.singleFormalParameterList;
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: DefaultFormalParameter
    parameter: SimpleFormalParameter
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: x
      declaredFragment: <testLibraryFragment> x@14
        element: isPublic
          type: int
    separator: =
    defaultValue: SimpleIdentifier
      token: x
      element: <null>
      staticType: InvalidType
    declaredFragment: <testLibraryFragment> x@14
      element: isPublic
        type: int
  rightDelimiter: }
  rightParenthesis: )
''');
  }
}
