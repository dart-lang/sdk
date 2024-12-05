// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralResolutionTest);
  });
}

@reflectiveTest
class ListLiteralResolutionTest extends PubPackageResolutionTest {
  test_hasTypeArguments_1() async {
    await assertNoErrorsInCode(r'''
void f() {
  <int>[];
}
''');

    var node = findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  leftBracket: [
  rightBracket: ]
  staticType: List<int>
''');
  }

  test_hasTypeArguments_2() async {
    await assertErrorsInCode(r'''
void f() {
  <int, double>[];
}
''', [
      error(CompileTimeErrorCode.EXPECTED_ONE_LIST_TYPE_ARGUMENTS, 13, 13),
    ]);

    var node = findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      NamedType
        name: double
        element: dart:core::<fragment>::@class::double
        element2: dart:core::<fragment>::@class::double#element
        type: double
    rightBracket: >
  leftBracket: [
  rightBracket: ]
  staticType: List<dynamic>
''');
  }

  test_noTypeArguments_hasElements() async {
    await assertNoErrorsInCode(r'''
void f() {
  [0];
}
''');

    var node = findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 0
      staticType: int
  rightBracket: ]
  staticType: List<int>
''');
  }

  test_noTypeArguments_hasElements_lub() async {
    await assertNoErrorsInCode(r'''
void f() {
  [0, 1.2];
}
''');

    var node = findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  leftBracket: [
  elements
    IntegerLiteral
      literal: 0
      staticType: int
    DoubleLiteral
      literal: 1.2
      staticType: double
  rightBracket: ]
  staticType: List<num>
''');
  }

  test_noTypeArguments_noElements() async {
    await assertNoErrorsInCode(r'''
void f() {
  [];
}
''');

    var node = findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
  staticType: List<dynamic>
''');
  }
}
