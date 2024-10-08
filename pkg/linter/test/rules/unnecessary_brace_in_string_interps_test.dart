// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryBraceInStringInterpsTest);
  });
}

@reflectiveTest
class UnnecessaryBraceInStringInterpsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.unnecessary_brace_in_string_interps;

  test_braces_bangAfter() async {
    await assertDiagnostics(r'''
void f() {
  print('hello ${int}!');
}
''', [
      lint(26, 6),
    ]);
  }

  test_braces_nonSimpleIdentifier() async {
    await assertNoDiagnostics(r'''
void f(int p) {
  print('hello ${p.hashCode}');
}
''');
  }

  test_braces_precededByDollar() async {
    await assertNoDiagnostics(r'''
void f() {
  var $int = 7;
  print('Value is: ${$int}');
}
''');
  }

  test_braces_simpleIdentifier() async {
    await assertDiagnostics(r'''
void f() {
  print('hello ${int}');
}
''', [
      lint(26, 6),
    ]);
  }

  test_braces_simpleIdentifier_numberAfter() async {
    await assertNoDiagnostics(r'''
void f() {
  print('hello ${int}1');
}
''');
  }

  test_braces_surroundedByUnderscores() async {
    await assertNoDiagnostics(r'''
void f() {
  print('hello _${int}_');
}
''');
  }

  test_noBraces() async {
    await assertNoDiagnostics(r'''
void f() {
  print('hello $int');
}
''');
  }

  test_noBraces_bangAfter() async {
    await assertNoDiagnostics(r'''
void f() {
  print('hello $int!');
}
''');
  }

  test_noInterpolation() async {
    await assertNoDiagnostics(r'''
void f() {
  print('hello');
}
''');
  }

  test_simpleIdentifier() async {
    await assertDiagnostics(r'''
void hi(String name) {
  print('hi: ${name}');
}
''', [
      lint(36, 7),
    ]);
  }

  test_simpleIdentifier_suffixed() async {
    await assertNoDiagnostics(r'''
void hi(String name) {
  print('hi: ${name}s');
}
''');
  }

  test_this_methodInvocation() async {
    await assertNoDiagnostics(r'''
class A {
  void hi() {
    print('hi: ${this.toString()}');
  }
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/3691
  test_thisExpression() async {
    await assertDiagnostics(r'''
class A {
  void hi() {
    print('hi: ${this}');
  }
}
''', [
      lint(39, 7),
    ]);
  }

  test_thisExpression_suffixed() async {
    await assertNoDiagnostics(r'''
class A {
  void hi() {
    print('${this}s');
  }
}
''');
  }
}
