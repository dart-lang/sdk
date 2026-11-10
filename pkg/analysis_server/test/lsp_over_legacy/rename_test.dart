// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameTest);
  });
}

/// More complete tests for textDocument/rename are in
/// 'test/lsp/rename_test.dart'.
@reflectiveTest
class RenameTest extends LspOverLegacyTest {
  Future<void> test_class() async {
    var code = TestCode.parse('''
class MyClass {}
var value = My^Class();
''');
    newFile(testFilePath, code.code);
    await initializeServer();

    var edit = await rename(
      testFileUri,
      null,
      code.position.position,
      'NewName',
    );

    verifyEdit(edit!, '''
>>>>>>>>>> lib/test.dart
class NewName {}
var value = NewName();
''');
  }
}
