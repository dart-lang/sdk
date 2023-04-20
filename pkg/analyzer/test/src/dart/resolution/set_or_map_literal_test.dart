// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SetOrMapLiteralResolutionTest);
  });
}

@reflectiveTest
class SetOrMapLiteralResolutionTest extends PubPackageResolutionTest {
  test_hasTypeArguments_1() async {
    await assertNoErrorsInCode(r'''
void f() {
  <int>{};
}
''');

    final node = findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: false
  staticType: Set<int>
''');
  }

  test_hasTypeArguments_2() async {
    await assertNoErrorsInCode(r'''
void f() {
  <int, String>{};
}
''');

    final node = findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: SimpleIdentifier
          token: int
          staticElement: dart:core::@class::int
          staticType: null
        type: int
      NamedType
        name: SimpleIdentifier
          token: String
          staticElement: dart:core::@class::String
          staticType: null
        type: String
    rightBracket: >
  leftBracket: {
  rightBracket: }
  isMap: true
  staticType: Map<int, String>
''');
  }

  test_noTypeArguments_hasElements_expression() async {
    await assertErrorsInCode(r'''
void f() {
  var v = {0};
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);

    final node = findNode.singleSetOrMapLiteral;
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
    await assertErrorsInCode(r'''
void f() {
  var v = {0: ''};
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);

    final node = findNode.singleSetOrMapLiteral;
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
    await assertErrorsInCode(r'''
void f() {
  var v = {};
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 17, 1),
    ]);

    final node = findNode.singleSetOrMapLiteral;
    assertResolvedNodeText(node, r'''
SetOrMapLiteral
  leftBracket: {
  rightBracket: }
  isMap: true
  staticType: Map<dynamic, dynamic>
''');
  }
}
