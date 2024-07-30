// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAugmentationDirectiveParserTest);
  });
}

@reflectiveTest
class LibraryAugmentationDirectiveParserTest extends ParserDiagnosticsTest {
  test_it() {
    var parseResult = parseStringWithErrors(r'''
augment library 'a.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleLibraryAugmentationDirective;
    assertParsedNodeText(node, r'''
LibraryAugmentationDirective
  augmentKeyword: augment
  libraryKeyword: library
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }
}
