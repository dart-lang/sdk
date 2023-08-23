// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LeadingNewlinesInMultilineStringsTest);
  });
}

@reflectiveTest
class LeadingNewlinesInMultilineStringsTest extends LintRuleTest {
  @override
  String get lintRule => 'leading_newlines_in_multiline_strings';

  test_emptyString() async {
    await assertNoDiagnostics(r"""
var x = '''''';
""");
  }

  test_leadingNewline() async {
    await assertNoDiagnostics(r"""
var x = '''
this is a multiline string''';
""");
  }

  test_leadingNewline_withInterpolation() async {
    await assertNoDiagnostics(r"""
var a = 'a';
var x = '''
this is a multiline string $a''';
""");
  }

  test_noNewline() async {
    await assertNoDiagnostics(r"""
var x = '''this is a multiline string''';
""");
  }

  test_noNewline_doubleQuotes() async {
    await assertNoDiagnostics(r'''
var x = """uses double quotes""";
''');
  }

  test_noNewline_interpolation() async {
    await assertNoDiagnostics(r"""
var a = 'a';
var x = '''$a''';
""");
  }

  test_noNewline_withInterpolation() async {
    await assertNoDiagnostics(r"""
var a = 'a';
var x = '''this is a multiline string $a''';
""");
  }

  test_textBeforeNewline() async {
    await assertDiagnostics(r"""
var x = '''this
 is a multiline string''';
""", [
      lint(8, 33),
    ]);
  }

  test_textBeforeNewline_withInterpolation() async {
    await assertDiagnostics(r"""
var a = 'a';
var x = '''this
 is a multiline string$a''';
""", [
      lint(21, 35),
    ]);
  }
}
