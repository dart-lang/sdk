// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationImportDirectiveParserTest);
  });
}

@reflectiveTest
class AugmentationImportDirectiveParserTest extends ParserDiagnosticsTest {
  test_it() {
    var parseResult = parseStringWithErrors(r'''
import augment 'a.dart';
''');
    parseResult.assertNoErrors();

    var node = parseResult.findNode.singleAugmentationImportDirective;
    assertParsedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
''');
  }

  test_noSemicolon() {
    var parseResult = parseStringWithErrors(r'''
import augment 'a.dart'
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 15, 8),
    ]);

    var node = parseResult.findNode.singleAugmentationImportDirective;
    assertParsedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ; <synthetic>
''');
  }

  test_noUri_hasSemicolon() {
    var parseResult = parseStringWithErrors(r'''
import augment ;
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_STRING_LITERAL, 15, 1),
    ]);

    var node = parseResult.findNode.singleAugmentationImportDirective;
    assertParsedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: "" <synthetic>
  semicolon: ;
''');
  }

  test_noUri_noSemicolon() {
    var parseResult = parseStringWithErrors(r'''
import augment
''');
    parseResult.assertErrors([
      error(ParserErrorCode.EXPECTED_TOKEN, 7, 7),
      error(ParserErrorCode.EXPECTED_STRING_LITERAL, 15, 0),
    ]);

    var node = parseResult.findNode.singleAugmentationImportDirective;
    assertParsedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: "" <synthetic>
  semicolon: ; <synthetic>
''');
  }
}
