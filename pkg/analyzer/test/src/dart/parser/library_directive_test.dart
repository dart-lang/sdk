// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../diagnostics/parser_diagnostics.dart';
import '../resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryDirectiveParserTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class LibraryDirectiveParserTest extends ParserDiagnosticsTest {
  void test_withName() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library name.and.dots;
''');

    var node = parseResult.findNode.singleLibraryDirective;
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  name: DottedName
    tokens
      name
      .
      and
      .
      dots
  semicolon: ;
''');
  }

  void test_withoutName() {
    var parseResult = parseTestCodeWithDiagnostics(r'''
library;
''');

    var node = parseResult.findNode.singleLibraryDirective;
    assertParsedNodeText(node, r'''
LibraryDirective
  libraryKeyword: library
  semicolon: ;
''');
  }
}
