// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentSymbolsTest);
  });
}

@reflectiveTest
class DocumentSymbolsTest extends LspOverLegacyTest {
  Future<void> test_symbols() async {
    final content = '''
class Aaa {}
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final results = await getDocumentSymbols(testFileUri);
    final names = results.map(
      (documentSymbols) =>
          documentSymbols.map((documentSymbol) => documentSymbol.name),
      (symbolInformation) =>
          symbolInformation.map((symbolInformation) => symbolInformation.name),
    );

    expect(names, contains('Aaa'));
  }
}
