// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EnumDeclarationParserTest);
  });
}

@reflectiveTest
class EnumDeclarationParserTest extends ParserDiagnosticsTest {
  test_augment() {
    var parseResult = parseStringWithErrors(r'''
augment library 'a.dart';

augment enum E {bar}
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleEnumDeclaration;
    assertParsedNodeText(node, r'''
EnumDeclaration
  augmentKeyword: augment
  enumKeyword: enum
  name: E
  leftBracket: {
  constants
    EnumConstantDeclaration
      name: bar
  rightBracket: }
''');
  }
}
