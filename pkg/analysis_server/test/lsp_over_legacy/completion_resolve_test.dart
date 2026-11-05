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
    defineReflectiveTests(CompletionResolveTest);
  });
}

/// More complete tests for completionItem/resolve are in
/// 'test/lsp/completion_*_test.dart'.
@reflectiveTest
class CompletionResolveTest extends LspOverLegacyTest {
  Future<void> test_classDocumentation() async {
    var code = TestCode.parse('''
/// This is MyClass with a long dartdoc that should be delayed until resolve
/// despite being in the same file as the completion request.
class MyClass {}

MyClas^
''');
    newFile(testFilePath, code.code);
    await initializeServer();

    var completions = await getCompletion(testFileUri, code.position.position);
    var completion = completions.singleWhere((item) => item.label == 'MyClass');
    expect(completion.documentation, isNull); // No docs before resolve

    var resolved = await resolveCompletion(completion);
    expect(resolved.documentation?.asString, contains('long dartdoc'));
  }
}
