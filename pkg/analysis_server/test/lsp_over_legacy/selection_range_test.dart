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
    defineReflectiveTests(SelectionRangeTest);
  });
}

/// More complete tests for textDocument/selectionRange are in
/// 'test/lsp/selection_range_test.dart'.
@reflectiveTest
class SelectionRangeTest extends LspOverLegacyTest {
  Future<void> test_identifier() async {
    var code = TestCode.parse('''
void f() {
  var value = 0;
  print/*[0*/(/*[1*/val^ue/*1]*/)/*0]*/;
}
''');
    newFile(testFilePath, code.code);
    await initializeServer();

    var range = await getSelectionRanges(testFileUri, code.position.position);
    expect(range.range, code.ranges[1].range);
    expect(range.parent!.range, code.ranges[0].range);
  }
}
