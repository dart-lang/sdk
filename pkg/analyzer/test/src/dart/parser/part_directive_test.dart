// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectiveParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class PartDirectiveParserTest extends ParserDiagnosticsTest {
  test_afterPartOf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part of 'a.dart';
part 'b.dart';
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_it() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part 'a.dart';
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }

  test_language305_afterPartOf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
part of 'a.dart';
part 'b.dart';
// [diag.nonPartOfDirectiveInPart][column 1][length 4] The part-of directive must be the only directive in a part.
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_language305_beforePartOf() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
// @dart = 3.5
part 'b.dart';
part of 'a.dart';
// [diag.nonPartOfDirectiveInPart][column 1][length 4] The part-of directive must be the only directive in a part.
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'b.dart'
  semicolon: ;
''');
  }

  test_noSemicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part 'a.dart'
//   ^^^^^^^^
// [diag.expectedToken] Expected to find ';'.
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ; <synthetic>
''');
  }

  test_noUri_hasSemicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part ;
//   ^
// [diag.expectedStringLiteral] Expected a string literal.
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: "" <synthetic>
  semicolon: ;
''');
  }

  test_noUri_noSemicolon() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
part
// [diag.expectedToken][column 1][length 4] Expected to find ';'.
//  ^
// [diag.expectedStringLiteral][column 5][length 0] Expected a string literal.
''');

    var node = parseResult.findNode.singlePartDirective;
    assertParsedNodeText(node, r'''
PartDirective
  partKeyword: part
  uri: SimpleStringLiteral
    literal: "" <synthetic>
  semicolon: ; <synthetic>
''');
  }
}
