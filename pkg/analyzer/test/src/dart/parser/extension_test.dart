// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclarationParserTest);
  });
}

@reflectiveTest
class ExtensionDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment_named() {
    final parseResult = parseStringWithErrors(r'''
library augment 'a.dart';

augment extension E on int {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  onKeyword: on
  extendedType: NamedType
    name: int
  leftBracket: {
  rightBracket: }
''');
  }

  test_augment_named_generic() {
    final parseResult = parseStringWithErrors(r'''
library augment 'a.dart';

augment extension E<T> on int {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  name: E
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  onKeyword: on
  extendedType: NamedType
    name: int
  leftBracket: {
  rightBracket: }
''');
  }

  test_augment_unnamed() {
    final parseResult = parseStringWithErrors(r'''
library augment 'a.dart';

augment extension on int {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  onKeyword: on
  extendedType: NamedType
    name: int
  leftBracket: {
  rightBracket: }
''');
  }

  test_augment_unnamed_generic() {
    final parseResult = parseStringWithErrors(r'''
library augment 'a.dart';

augment extension<T> on int {}
''');
    parseResult.assertNoErrors();

    final node = parseResult.findNode.singleExtensionDeclaration;
    assertParsedNodeText(node, r'''
ExtensionDeclaration
  augmentKeyword: augment
  extensionKeyword: extension
  typeParameters: TypeParameterList
    leftBracket: <
    typeParameters
      TypeParameter
        name: T
    rightBracket: >
  onKeyword: on
  extendedType: NamedType
    name: int
  leftBracket: {
  rightBracket: }
''');
  }
}
