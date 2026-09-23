// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentLinkTest);
  });
}

/// More complete tests for textDocument/documentLink are in
/// 'test/lsp/document_link_test.dart'.
@reflectiveTest
class DocumentLinkTest extends LspOverLegacyTest {
  Future<void> test_exampleDirective() async {
    var linkedFilePath = pathContext.join(
      projectFolderPath,
      'examples',
      'example.dart',
    );
    var code = TestCode.parse('''
/// {@example [!/examples/example.dart!] }
class A {}
''');
    newFile(linkedFilePath, '');
    newFile(testFilePath, code.code);
    await initializeServer();

    var links = await getDocumentLinks(testFileUri);
    var link = links!.single;
    expect(link.range, code.range.range);
    expect(link.target, toUri(linkedFilePath));
  }
}
