// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentHighlightsTest);
  });
}

@reflectiveTest
class DocumentHighlightsTest extends LspOverLegacyTest {
  Future<void> test_highlights() async {
    final content = '''
var ^a = '';
void f() {
  a = '';
  print(a);
}
''';
    final code = TestCode.parse(content);
    newFile(testFilePath, code.code);
    final results =
        await getDocumentHighlights(testFileUri, code.position.position);
    expect(results, hasLength(3));
  }
}
