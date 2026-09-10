// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../lsp/utils/semantic_tokens.dart';
import '../utils/test_code_extensions.dart';
import 'abstract_lsp_over_legacy.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SemanticTokensTest);
  });
}

/// More complete tests for semantic tokens are in
/// 'test/lsp/semantic_tokens_test.dart'.
@reflectiveTest
class SemanticTokensTest extends LspOverLegacyTest
    with SemanticTokensTestMixin {
  Future<void> test_full() async {
    var code = TestCode.parseNormalized('''
class A(final String x);
''');

    var expected = [
      Token('class', .keyword),
      Token('A', .class_, [.declaration]),
      Token('final', .keyword),
      Token('String', .class_),
      Token('x', .parameter, [.declaration]),
    ];

    await _initializeAndVerifyTokens(code, expected);
  }

  Future<void> test_range() async {
    var code = TestCode.parseNormalized('''
class [!A!](final String x);
''');

    var expected = [
      Token('A', .class_, [.declaration]),
    ];

    await _initializeAndVerifyTokens(code, expected, range: code.range.range);
  }

  /// Initializes the server with [content] in [uri] and then checks the
  /// semantic tokens for the marked range match [expected].
  ///
  /// [content] will be normalized for the line endings being used for the test
  /// run.
  Future<void> _initializeAndVerifyTokens(
    TestCode code,
    List<Token> expected, {
    Range? range,
  }) async {
    newFile(testFilePath, code.code);
    await initializeServer();

    var tokens = range != null
        ? await getSemanticTokensRange(testFileUri, code.range.range)
        : await getSemanticTokens(testFileUri);
    var decoded = decodeSemanticTokens(code.code, tokens);
    expect(decoded, equals(expected));
  }
}
