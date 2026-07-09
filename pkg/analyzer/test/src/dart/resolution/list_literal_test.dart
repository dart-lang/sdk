// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ListLiteralResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ListLiteralResolutionTest extends PubPackageResolutionTest {
  test_hasTypeArguments_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  <int>[];
}
''');

    var node = result.findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: [
  rightBracket: ]
  staticType: List<int>
''');
  }

  test_hasTypeArguments_2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  <int, double>[];
//^^^^^^^^^^^^^
// [diag.expectedOneListTypeArguments] List literals require one type argument or none, but 2 found.
}
''');

    var node = result.findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: double
        element: dart:core::@class::double
        type: double
    rightBracket: >
  leftBracket: [
  rightBracket: ]
  staticType: List<dynamic>
''');
  }

  test_noTypeArguments_hasElements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  [0];
}
''');

    var node = result.findNode.singleListLiteral;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  [0, 1.2];
}
''');

    var node = result.findNode.singleListLiteral;
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  [];
}
''');

    var node = result.findNode.singleListLiteral;
    assertResolvedNodeText(node, r'''
ListLiteral
  leftBracket: [
  rightBracket: ]
  staticType: List<dynamic>
''');
  }
}
