// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConstWithNonTypeTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ConstWithNonTypeTest extends PubPackageResolutionTest {
  test_annotation() async {
    await resolveTestCodeWithDiagnostics(r'''
@Unresolved()
// [diag.constWithNonType][column 2][length 10] The name 'Unresolved' isn't a class.
void f() {}
''');
  }

  test_annotation_functionTypeAlias_typeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef F<T> = void Function(T);

@F<int>.toString()
// [diag.constWithNonType][column 2][length 1] The name 'F' isn't a class.
void f() {}
''');

    var node = result.findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  expression: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: F
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::F
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: toString
      element: <null>
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: InvalidType
  name: SimpleIdentifier
    token: F
    element: <testLibrary>::@typeAlias::F
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
''');
  }

  test_annotation_importPrefix() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as p;

@p.A(0)
// ^
// [diag.constWithNonType] The name 'A' isn't a class.
void f() {}
''');
  }

  test_annotation_recordTypeAlias_typeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef R<T> = (T,);

@R<int>.toString()
// [diag.constWithNonType][column 2][length 1] The name 'R' isn't a class.
void f() {}
''');

    var node = result.findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  expression: ConstructorInvocation
    constructorReference: ConstructorReference2
      typeReference: ConstructorTypeReference
        name: R
        typeArguments: TypeArgumentList
          leftBracket: <
          arguments
            NamedType
              name: int
              element: dart:core::@class::int
              type: int
          rightBracket: >
        element: <testLibrary>::@typeAlias::R
        type: InvalidType
      selector: ConstructorSelector
        period: .
        name2: toString
      element: <null>
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: InvalidType
  name: SimpleIdentifier
    token: R
    element: <testLibrary>::@typeAlias::R
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: toString
    element: <null>
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  element: <null>
''');
  }

  test_fromLibrary() async {
    newFile('$testPackageLibPath/lib1.dart', '');
    await resolveTestCodeWithDiagnostics(r'''
import 'lib1.dart' as lib;
void f() {
  const lib.A();
//          ^
// [diag.constWithNonType] The name 'A' isn't a class.
}
''');
  }

  test_variable() async {
    await resolveTestCodeWithDiagnostics(r'''
int A = 0;
f() {
  return const A();
//             ^
// [diag.constWithNonType] The name 'A' isn't a class.
}
''');
  }
}
