// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
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
    await assertDiagnostics(
      r'''
class A {
  A() : assert(true);
}
''',
      [lint(18, 12)],
    );
  }

  test_assertInitializer_primaryConstructorBody_message() async {
    await assertNoDiagnostics(r'''
class C(int x) {
  this : assert(x > 0, 'x must be positive');
}
''');
  }

  test_assertInitializer_primaryConstructorBody_noMessage() async {
    await assertDiagnostics(
      r'''
class C(int x) {
  this : assert(x > 0);
}
''',
      [lint(26, 13)],
    );
  }

  test_assertStatement_message() async {
    await assertNoDiagnostics(r'''
void f() {
  assert(true, '');
}
''');
  }

  test_assertStatement_noMessage() async {
    await assertDiagnostics(
      r'''
void f() {
  assert(true);
}
''',
      [lint(13, 13)],
    );
  }

  test_assertStatement_primaryConstructorBody_noMessage() async {
    await assertDiagnostics(
      r'''
class C(int x) {
  this {
    assert(x > 0);
  }
}
''',
      [lint(30, 14)],
    );
  }

  test_enum_assertInitializer_primaryConstructorBody_noMessage() async {
    await assertDiagnostics(
      r'''
enum E(int x) {
  e1(1);
  this : assert(x > 0);
}
''',
      [lint(34, 13)],
    );
  }

  test_extensionType_assertInitializer_primaryConstructorBody_noMessage() async {
    await assertDiagnostics(
      r'''
extension type E(int x) {
  this : assert(x > 0);
}
''',
      [lint(35, 13)],
    );
  }
}
