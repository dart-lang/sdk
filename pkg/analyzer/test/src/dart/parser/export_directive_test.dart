// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExportDirectiveParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ExportDirectiveParserTest extends ParserDiagnosticsTest {
  test_afterPart() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part 'a.dart';
export 'b.dart';
// [diag.exportDirectiveAfterPartDirective][column 1][length 6] Export directives must precede part directives.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart';
export 'b.dart';
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'foo.dart'
  if (dart.library.html) 'foo_html.dart';
''');

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
        tokens
          dart
          .
          library
          .
          html
      rightParenthesis: )
      uri: SimpleStringLiteral
        literal: 'foo_html.dart'
      resolvedUri: <null>
  semicolon: ;
''');
  }

  test_it() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'a.dart';
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
part of 'a.dart';
export 'b.dart';
// [diag.nonPartOfDirectiveInPart][column 1][length 6] The part-of directive must be the only directive in a part.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
export 'b.dart';
part of 'a.dart';
// [diag.nonPartOfDirectiveInPart][column 1][length 4] The part-of directive must be the only directive in a part.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
export 'a.dart'
//     ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
export ;
//     ^
// [diag.expectedStringLiteral] Expected a string literal.
''');

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
    var parseResult = parseTestCodeWithDiagnostics(r'''
export
// [diag.expectedToken][column 1][length 6] Expected to find ';'.
//    ^
// [diag.expectedStringLiteral][column 7][length 0] Expected a string literal.
''');

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
