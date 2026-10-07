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
    defineReflectiveTests(PrepareRenameTest);
  });
}

/// More complete tests for textDocument/prepareRename are in
/// 'test/lsp/rename_test.dart'.
@reflectiveTest
class PrepareRenameTest extends LspOverLegacyTest {
  Future<void> test_class() async {
    var code = TestCode.parse('''
class MyClass {}
var value = [!My^Class!]();
''');
    newFile(testFilePath, code.code);
    await initializeServer();

    var placeholder = await prepareRename(testFileUri, code.position.position);
    expect(placeholder!.placeholder, 'MyClass');
    expect(placeholder.range, code.range.range);
  }
}
