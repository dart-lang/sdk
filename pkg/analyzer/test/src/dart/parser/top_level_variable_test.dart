// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TopLevelVariableParserTest);
  });
}

@reflectiveTest
class TopLevelVariableParserTest extends ParserDiagnosticsTest {
  test_augment() {
    var parseResult = parseStringWithErrors(r'''
augment final foo = 0;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  augmentKeyword: augment
  variables: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: foo
        equals: =
        initializer: IntegerLiteral
          literal: 0
  semicolon: ;
''');
  }

  test_external() {
    var parseResult = parseStringWithErrors(r'''
external int foo;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleTopLevelVariableDeclaration;
    assertParsedNodeText(node, r'''
TopLevelVariableDeclaration
  externalKeyword: external
  variables: VariableDeclarationList
    type: NamedType
      name: int
    variables
      VariableDeclaration
        name: foo
  semicolon: ;
''');
  }
}
