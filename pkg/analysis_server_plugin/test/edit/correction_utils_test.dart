// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CorrectionUtilsTest);
  });
}

@reflectiveTest
final class CorrectionUtilsTest extends SingleUnitTest {
  Future<void> assert_invertCondition(String expr, String expected) async {
    await resolveTestCode('''
void f(bool? b4, bool? b5) {
  int? v1, v2, v3, v4, v5;
  bool b1 = true, b2 = true, b3 = true;
  if ($expr) {
    0;
  } else {
    1;
  }
}
''');
    var ifStatement = findNode.ifStatement('if (');
    var condition = ifStatement.expression;
    var result = CorrectionUtils(testAnalysisResult).invertCondition(condition);
    expect(result, expected);
    // For compactness we put multiple cases into one test method.
    // Prepare for resolving the test file one again.
    changeFile(testFile);
  }

  Future<void> assertReplacedIndentation(
    String source,
    String expected, {
    String indentOld = '  ',
    String indentNew = '    ',
    bool includeLeading = false,
    bool ensureTrailingNewline = false,
  }) async {
    await parseTestCode(source);
    var util = CorrectionUtils(testParsedResult);
    var actual = util.replaceSourceIndent(
      testCode,
      indentOld,
      indentNew,
      includeLeading: includeLeading,
      ensureTrailingNewline: ensureTrailingNewline,
    );
    expect(actual, expected);
  }

  Future<void> test_invertCondition_binary_compare() async {
    await assert_invertCondition('0 < 1', '0 >= 1');
    await assert_invertCondition('0 > 1', '0 <= 1');
    await assert_invertCondition('0 <= 1', '0 > 1');
    await assert_invertCondition('0 >= 1', '0 < 1');
    await assert_invertCondition('0 == 1', '0 != 1');
    await assert_invertCondition('0 != 1', '0 == 1');
  }

  Future<void> test_invertCondition_binary_compare_boolean() async {
    await assert_invertCondition('b4 == null', 'b4 != null');
    await assert_invertCondition('b4 != null', 'b4 == null');
  }

  Future<void> test_invertCondition_binary_logical() async {
    await assert_invertCondition('b1 && b2', '!b1 || !b2');
    await assert_invertCondition('!b1 && !b2', 'b1 || b2');
    await assert_invertCondition('b1 || b2', '!b1 && !b2');
    await assert_invertCondition('!b1 || !b2', 'b1 && b2');
  }

  Future<void> test_invertCondition_complex() async {
    await assert_invertCondition('b1 && b2 || b3', '(!b1 || !b2) && !b3');
    await assert_invertCondition('b1 || b2 && b3', '!b1 && (!b2 || !b3)');
    await assert_invertCondition('(!b1 || !b2) && !b3', 'b1 && b2 || b3');
    await assert_invertCondition('!b1 && (!b2 || !b3)', 'b1 || b2 && b3');
  }

  Future<void> test_invertCondition_is() async {
    await assert_invertCondition('v1 is int', 'v1 is! int');
    await assert_invertCondition('v1 is! int', 'v1 is int');
  }

  Future<void> test_invertCondition_literal() async {
    await assert_invertCondition('true', 'false');
    await assert_invertCondition('false', 'true');
  }

  Future<void> test_invertCondition_not() async {
    await assert_invertCondition('b1', '!b1');
    await assert_invertCondition('!b1', 'b1');
    await assert_invertCondition('!((b1))', 'b1');
    await assert_invertCondition('(((b1)))', '!b1');
  }

  Future<void> test_replaceSourceIndent_leading_empty_crlf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      indentOld: '',
      indentNew: '  ',
      'a\r\nb\r\nc',
      '  a\r\n  b\r\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_leading_empty_lf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      indentOld: '',
      indentNew: '  ',
      'a\nb\nc',
      '  a\n  b\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_leading_nonEmpty_crlf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      '  a\r\n  b\r\n  c',
      '    a\r\n    b\r\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_leading_nonEmpty_lf() async {
    await assertReplacedIndentation(
      includeLeading: true,
      '  a\n  b\n  c',
      '    a\n    b\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_empty_crlf() async {
    await assertReplacedIndentation(
      indentOld: '',
      indentNew: '  ',
      'a\r\nb\r\nc',
      'a\r\n  b\r\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_empty_lf() async {
    await assertReplacedIndentation(
      indentOld: '',
      indentNew: '  ',
      'a\nb\nc',
      'a\n  b\n  c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_nonEmpty_crlf() async {
    await assertReplacedIndentation(
      '  a\r\n  b\r\n  c',
      '  a\r\n    b\r\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noLeading_nonEmpty_lf() async {
    await assertReplacedIndentation(
      '  a\n  b\n  c',
      '  a\n    b\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noTrailing_crlf() async {
    await assertReplacedIndentation(
      '  a\r\n  b\r\n  c',
      '  a\r\n    b\r\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_noTrailing_lf() async {
    await assertReplacedIndentation(
      '  a\n  b\n  c',
      '  a\n    b\n    c',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_added_crlf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\r\n  b\r\n  c',
      '  a\r\n    b\r\n    c\r\n',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_added_lf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\n  b\n  c',
      '  a\n    b\n    c\n',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_existing_added_lf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\n  b\n  c\n',
      '  a\n    b\n    c\n',
    );
  }

  Future<void> test_replaceSourceIndent_trailing_existing_crlf() async {
    await assertReplacedIndentation(
      ensureTrailingNewline: true,
      '  a\r\n  b\r\n  c\r\n',
      '  a\r\n    b\r\n    c\r\n',
    );
  }
}
