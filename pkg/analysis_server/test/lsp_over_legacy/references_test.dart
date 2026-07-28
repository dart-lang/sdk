// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReferencesTest);
  });
}

/// More complete tests for textDocument/references are in
/// 'test/lsp/references_test.dart'.
@reflectiveTest
class ReferencesTest extends LspOverLegacyTest {
  Future<void> test_variable() async {
    var contents = '''
var a^ = 1;
void foo() {
  [!a!];
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

    var res = await getReferences(testFileUri, code.position.position);

    var expected = [
      for (final range in code.ranges)
        Location(uri: testFileUri, range: range.range),
    ];

    // Checking sets produces a better failure message than lists
    // (it'll show which item is missing instead of just saying
    // the lengths are different), so check that first.
    expect(res.toSet(), expected.toSet());
    // But also check the list in case there were unexpected duplicates.
    expect(res, unorderedEquals(expected));
  }
}
