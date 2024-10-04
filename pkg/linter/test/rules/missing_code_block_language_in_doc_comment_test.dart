// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingCodeBlockLanguageInDocCommentTest);
  });
}

@reflectiveTest
class MissingCodeBlockLanguageInDocCommentTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.missing_code_block_language_in_doc_comment;

  test_hasLanguage() async {
    await assertNoDiagnostics(r'''
/// ```dart
/// test
/// ```
class A {}
''');
  }

  test_hasLanguage_leadingWhitespace() async {
    await assertNoDiagnostics(r'''
///   ```dart
/// test
/// ```
class A {}
''');
  }

  test_hasLanguage_noEndingFence() async {
    await assertNoDiagnostics(r'''
/// ```dart
/// test
/// more test
class A {}
''');
  }

  test_indentedCodeBlock() async {
    await assertNoDiagnostics(r'''
/// Example:
///
///     var printer = Printer();
///     printer.printToStdout();
///
class A {}
''');
  }

  test_missingLanguage() async {
    await assertDiagnostics(r'''
/// ```
/// test
/// ```
class A {}
''', [
      lint(3, 4),
    ]);
  }

  test_missingLanguage_leadingWhitespace() async {
    await assertDiagnostics(r'''
///   ```
/// test
/// ```
class A {}
''', [
      lint(3, 6),
    ]);
  }

  test_missingLanguage_noEndingFence() async {
    await assertDiagnostics(r'''
/// ```
/// test
/// more test
class A {}
''', [
      lint(3, 4),
    ]);
  }
}
