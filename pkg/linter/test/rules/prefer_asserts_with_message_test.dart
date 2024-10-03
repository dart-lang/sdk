// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferAssertsWithMessageTest);
  });
}

@reflectiveTest
class PreferAssertsWithMessageTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_asserts_with_message;

  test_assertInitializer_message() async {
    await assertNoDiagnostics(r'''
class A {
  A() : assert(true, '');
}
''');
  }

  test_assertInitializer_noMessage() async {
    await assertDiagnostics(r'''
class A {
  A() : assert(true);
}
''', [
      lint(18, 12),
    ]);
  }

  test_assertStatement_message() async {
    await assertNoDiagnostics(r'''
void f() {
  assert(true, '');
}
''');
  }

  test_assertStatement_noMessage() async {
    await assertDiagnostics(r'''
void f() {
  assert(true);
}
''', [
      lint(13, 13),
    ]);
  }
}
