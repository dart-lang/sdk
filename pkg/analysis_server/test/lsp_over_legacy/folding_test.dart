// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FoldingTest);
  });
}

/// More complete tests for textDocument/foldingRange are in
/// 'test/lsp/folding_test.dart'.
@reflectiveTest
class FoldingTest extends LspOverLegacyTest {
  Future<void> test_class() async {
    var code = TestCode.parse('''
class A {/*[0*/
  void f() {}
/*0]*/}
''');
    newFile(testFilePath, code.code);
    await initializeServer();

    var ranges = await getFoldingRanges(testFileUri);
    var range = code.ranges.single.range;
    expect(ranges, [
      FoldingRange(
        startLine: range.start.line,
        startCharacter: range.start.character,
        endLine: range.end.line,
        endCharacter: range.end.character,
      ),
    ]);
  }
}
