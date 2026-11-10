// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/lsp_protocol_extensions.dart';
import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CompletionTest);
  });
}

/// More complete tests for textDocument/completion are in
/// 'test/lsp/completion_*_test.dart'.
@reflectiveTest
class CompletionTest extends LspOverLegacyTest {
  Future<void> test_simpleClass() async {
    var contents = '''
/// My class.
class MyClass {}

MyClas^
''';

    var code = TestCode.parse(contents);
    newFile(testFilePath, code.code);
    await initializeServer();

    var completions = await getCompletion(testFileUri, code.position.position);
    expect(completions, hasLength(1));
    var completion = completions.single;
    expect(completion.label, 'MyClass');
    expect(completion.documentation?.asString, 'My class.');
  }
}
