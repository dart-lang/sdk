// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PartDirectiveParserTest);
  });
}

@reflectiveTest
class PartDirectiveParserTest extends ParserDiagnosticsTest {
  test_afterPartOf() {
    var parseResult = parseStringWithErrors(r'''
part of 'a.dart';
part 'b.dart';
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
part 'a.dart';
''');
    parseResult.assertNoErrors();

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
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
part of 'a.dart';
part 'b.dart';
''');
    parseResult.assertErrors([
      error(ParserErrorCode.nonPartOfDirectiveInPart, 33, 4),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
// @dart = 3.5
part 'b.dart';
part of 'a.dart';
''');
    parseResult.assertErrors([
      error(ParserErrorCode.nonPartOfDirectiveInPart, 30, 4),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
part 'a.dart'
''');
    parseResult.assertErrors([error(ParserErrorCode.expectedToken, 5, 8)]);

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
    var parseResult = parseStringWithErrors(r'''
part ;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedStringLiteral, 5, 1),
    ]);

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
    var parseResult = parseStringWithErrors(r'''
part
''');
    parseResult.assertErrors([
      error(ParserErrorCode.expectedToken, 0, 4),
      error(ParserErrorCode.expectedStringLiteral, 5, 0),
    ]);

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
