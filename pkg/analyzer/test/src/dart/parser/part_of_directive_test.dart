// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartOfDirectiveParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PartOfDirectiveParserTest extends ParserDiagnosticsTest {
  test_name() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of my.library;
//      ^^^^^^^^^^
// [diag.partOfName] The 'part of' directive can't use a name with the enhanced-parts feature.
''');

    var node = parseResult.findNode.singlePartOfDirective;
    assertParsedNodeText(node, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: DottedName
    tokens
      my
      .
      library
  semicolon: ;
''');
  }

  test_name_preEnhancedParts() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.4
part of my.library;
''');

    var node = parseResult.findNode.singlePartOfDirective;
    assertParsedNodeText(node, r'''
PartOfDirective
  partKeyword: part
  ofKeyword: of
  libraryName: DottedName
    tokens
      my
      .
      library
  semicolon: ;
''');
  }

  test_uri() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart';
''');

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
