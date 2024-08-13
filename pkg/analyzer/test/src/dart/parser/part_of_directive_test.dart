// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartOfDirectiveParserTest);
  });
}

@reflectiveTest
class PartOfDirectiveParserTest extends ParserDiagnosticsTest {
  test_name() {
    var parseResult = parseStringWithErrors(r'''
part of my.library;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.PART_OF_NAME, 8, 10),
    ]);

    var node = parseResult.findNode.singlePartOfDirective;
    assertParsedNodeText(node, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: LibraryIdentifier
    components
      SimpleIdentifier
        token: my
      SimpleIdentifier
        token: library
  semicolon: ;
''');
  }

  test_name_preEnhancedParts() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.4
part of my.library;
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePartOfDirective;
    assertParsedNodeText(node, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: LibraryIdentifier
    components
      SimpleIdentifier
        token: my
      SimpleIdentifier
        token: library
  semicolon: ;
''');
  }

  test_uri() {
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singlePartOfDirective;
    assertParsedNodeText(node, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }
}
