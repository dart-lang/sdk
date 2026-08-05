// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetOrMapLiteralResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class SetOrMapLiteralResolutionTest extends PubPackageResolutionTest {
  test_hasTypeArguments_1() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  <int>{};
}
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: false
  staticType: Set<int>
''');
  }

  test_hasTypeArguments_2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  <int, String>{};
}
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
      NamedType
        name: String
        element: dart:core::@class::String
        type: String
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: true
  staticType: Map<int, String>
''');
  }

  test_noTypeArguments_hasElements_expression() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var v = {0};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    IntegerLiteral
      literal: 0
      staticType: int
  rightBracket: }
  isMap: false
  staticType: Set<int>
''');
  }

  test_noTypeArguments_hasElements_mapEntry() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var v = {0: ''};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  elements
    MapLiteralEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: SimpleStringLiteral
        literal: ''
  rightBracket: }
  isMap: true
  staticType: Map<int, String>
''');
  }

  test_noTypeArguments_noElements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var v = {};
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'v' isn't used.
}
''');

    var node = result.findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  rightBracket: }
  isMap: true
  staticType: Map<dynamic, dynamic>
''');
  }
}
