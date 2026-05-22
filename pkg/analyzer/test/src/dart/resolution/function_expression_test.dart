// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FunctionExpressionResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class FunctionExpressionResolutionTest extends PubPackageResolutionTest {
  test_genericFunctionExpression_fBoundedDefaultType() async {
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  <T extends List<T>>() {};
}
''');

    var node = result.findNode.functionExpression('<T extends');
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
    var result = await resolveTestCodeWithDiagnostics('''
void f() {
  <T extends num>() {};
}
''');

    var node = result.findNode.functionExpression('<T extends');
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
    var result = await resolveTestCodeWithDiagnostics('''
var f = ({int x = x}) {};
//                ^
// [diag.undefinedIdentifier] Undefined name 'x'.
''');

    var node = result.findNode.singleFormalParameterList;
    assertResolvedNodeText(node, r'''
FormalParameterList
  leftParenthesis: (
  leftDelimiter: {
  parameter: RegularFormalParameter
    type: NamedType
      name: int
      element: dart:core::@class::int
      type: int
    name: x
    defaultClause: FormalParameterDefaultClause
      separator: =
      value: SimpleIdentifier
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
