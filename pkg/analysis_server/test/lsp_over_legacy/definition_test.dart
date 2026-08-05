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
    defineReflectiveTests(DefinitionTest);
  });
}

/// More complete tests for textDocument/definition are in
/// 'test/lsp/definition_test.dart'.
@reflectiveTest
class DefinitionTest extends LspOverLegacyTest {
  Future<void> test_variable() async {
    var contents = '''
var [!a!] = 1;
void foo() {
  a^;
}
''';

    await testContents(contents);
  }

  /// Expects definitions at the location of `^` in [contents] will navigate to
  /// the range in `[!` brackets `!]` in `[contents].
  Future<void> testContents(String contents) async {
    var code = TestCode.parse(contents);
    newFile(testFilePath, code.code);
    await waitForTasksFinished();

    var res = await getDefinitionAsLocation(
      testFileUri,
      code.position.position,
    );

    expect(code.ranges, hasLength(1));
    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(code.range.range));
    expect(loc.uri, equals(testFileUri));
  }
}
