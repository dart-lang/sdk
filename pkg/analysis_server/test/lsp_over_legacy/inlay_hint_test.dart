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
    defineReflectiveTests(InlayHintTest);
  });
}

/// More complete tests for textDocument/inlayHint are in
/// 'test/lsp/inlay_hint_test.dart'.
@reflectiveTest
class InlayHintTest extends LspOverLegacyTest {
  Future<void> test_variableType() async {
    var contents = '''
[!final a = 1;!]
''';

    var code = TestCode.parse(contents);
    newFile(testFilePath, code.code);
    await initializeServer();

    var hints = await getInlayHints(testFileUri, code.range.range);

    expect(hints, hasLength(1));
    expect(hints.single.kind, InlayHintKind.Type);
  }
}
