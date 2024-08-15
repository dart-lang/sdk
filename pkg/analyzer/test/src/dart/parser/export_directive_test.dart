// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDirectiveParserTest);
  });
}

@reflectiveTest
class ExportDirectiveParserTest extends ParserDiagnosticsTest {
  test_afterPart() {
    var parseResult = parseStringWithErrors(r'''
part 'a.dart';
export 'b.dart';
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPORT_DIRECTIVE_AFTER_PART_DIRECTIVE, 15, 6),
    ]);

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_afterPartOf() {
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart';
export 'b.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_configurableUri() {
    var parseResult = parseStringWithErrors(r'''
export 'foo.dart'
  if (dart.library.html) 'foo_html.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'foo.dart'
  configurations
    Configuration
      ifKeyword: if
      leftParenthesis: (
      name: DottedName
        components
          SimpleIdentifier
            token: dart
          SimpleIdentifier
            token: library
          SimpleIdentifier
            token: html
      rightParenthesis: )
      uri: SimpleStringLiteral
        literal: 'foo_html.dart'
      resolvedUri: <null>
  semicolon: ;
''');
  }

  test_it() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }

  test_language305_afterPartOf() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
part of 'a.dart';
export 'b.dart';
''');
    parseResult.assertErrors([
      error(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, 33, 6),
    ]);

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_language305_beforePartOf() {
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
export 'b.dart';
part of 'a.dart';
''');
    parseResult.assertErrors([
      error(ParserErrorCode.NON_PART_OF_DIRECTIVE_IN_PART, 32, 4),
    ]);

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_noSemicolon() {
    var parseResult = parseStringWithErrors(r'''
export 'a.dart'
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 7, 8),
    ]);

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ; <synthetic>
''');
  }

  test_noUri_hasSemicolon() {
    var parseResult = parseStringWithErrors(r'''
export ;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_STRING_LITERAL, 7, 1),
    ]);

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: "" <synthetic>
  semicolon: ;
''');
  }

  test_noUri_noSemicolon() {
    var parseResult = parseStringWithErrors(r'''
export
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 0, 6),
      error(ParserErrorCode.EXPECTED_STRING_LITERAL, 7, 0),
    ]);

    var node = parseResult.findNode.singleExportDirective;
    assertParsedNodeText(node, r'''
ExportDirective
  exportKeyword: export
  uri: SimpleStringLiteral
    literal: "" <synthetic>
  semicolon: ; <synthetic>
''');
  }
}
