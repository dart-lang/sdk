// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEscapingInnerQuotesTest);
  });
}

@reflectiveTest
class AvoidEscapingInnerQuotesTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_escaping_inner_quotes';

  test_doubleQuotes_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  print("");
}
''');
  }

  test_doubleQuotes_escapedQuote() async {
    await assertDiagnostics(r'''
void f() {
  print("\"");
}
''', [
      lint(19, 4),
    ]);
  }

  test_doubleQuotes_escapedQuote_withInterpolation() async {
    await assertDiagnostics(r'''
void f() {
  print("\"$f");
}
''', [
      lint(19, 6),
    ]);
  }

  test_doubleQuotes_escapedQuote_withSingleQuote() async {
    await assertNoDiagnostics(r'''
void f() {
  print("\"'");
}
''');
  }

  test_doubleQuotes_escapedQuote_withSingleQuote_andInterpolation() async {
    await assertNoDiagnostics(r'''
void f() {
  print("\"'$f");
}
''');
  }

  test_singleQuotes() async {
    await assertDiagnostics(r'''
void f(String d) {
  print('a\'b\'c ${d.length}');
}
''', [
      lint(27, 21),
    ]);
  }

  test_singleQuotes_empty() async {
    await assertNoDiagnostics(r'''
void f() {
  print('');
}
''');
  }

  test_singleQuotes_escapedQuote() async {
    await assertDiagnostics(r'''
void f() {
  print('\'');
}
''', [
      lint(19, 4),
    ]);
  }

  test_singleQuotes_escapedQuote_withDoubleQuote() async {
    await assertNoDiagnostics(r'''
void f() {
  print('\'"');
}
''');
  }

  test_singleQuotes_escapedQuote_withDoubleQuote_andInterpolation() async {
    await assertNoDiagnostics(r'''
void f() {
  print('\'"$f');
}
''');
  }

  test_singleQuotes_escapedQuote_withInterpolation() async {
    await assertDiagnostics(r'''
void f() {
  print('\'$f');
}
''', [
      lint(19, 6),
    ]);
  }
}
