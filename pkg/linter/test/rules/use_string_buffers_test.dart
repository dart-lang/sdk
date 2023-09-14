// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseStringBuffersTest);
  });
}

@reflectiveTest
class UseStringBuffersTest extends LintRuleTest {
  @override
  String get lintRule => 'use_string_buffers';

  test_field_nonString_plus() async {
    await assertNoDiagnostics(r'''
class B {
  operator +(B other) => this;

  void m() {
    B b = B();
    for (var i = 0; i < 10; i++) {
      b = b + this;
    }
  }
}
''');
  }

  test_field_nonString_plusEquals() async {
    await assertNoDiagnostics(r'''
class B {
  operator +(B other) => this;

  void m() {
    B b = B();
    for (var i = 0; i < 10; i++) {
      b += this;
    }
  }
}
''');
  }

  test_field_plus_bufferReference() async {
    await assertNoDiagnostics(r'''
class A {
  String buffer = '';

  void foo() {
    buffer = buffer + buffer;
  }
}
''');
  }

  test_field_plusEquals_nonStringLiteral() async {
    await assertDiagnostics(r'''
class A {
  String buffer = '';

  void foo(int n) {
    int aux = n;
    while (aux-- > 0) {
      buffer += ''.toLowerCase();
    }
  }
}
''', [
      lint(100, 26),
    ]);
  }

  test_field_plusEquals_stringLiteral() async {
    await assertDiagnostics(r'''
class A {
  String buffer = '';

  void foo(int n) {
    int aux = n;
    while (aux-- > 0) {
      buffer += 'a';
    }
  }
}
''', [
      lint(100, 13),
    ]);
  }

  test_localVariable_assignment_interpolatedStringLiteralAsPrefix() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = '${buffer}a';
  }
}
''', [
      lint(69, 6),
    ]);
  }

  test_localVariable_assignment_interpolatedStringLiteralAsPrefixWithPlus() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = '${buffer + 'a'}a';
  }
}
''', [
      lint(69, 6),
    ]);
  }

  test_localVariable_assignment_interpolatedStringLiteralNotAsPrefix() async {
    await assertNoDiagnostics(r'''
void foo() {
  var buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = 'a$buffer';
  }
}
''');
  }

  test_localVariable_doLoop_plusEquals_stringLiteral() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  do {
    buffer += 'a';
  } while (buffer.length < 10);
}
''', [
      lint(43, 13),
    ]);
  }

  test_localVariable_plus_stringLiteral() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer = buffer + 'a';
  }
}
''', [
      lint(69, 6),
    ]);
  }

  test_localVariable_plusEquals_nonStringLiteral() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  for (final s in ['a']) {
    buffer += s;
  }
}
''', [
      lint(63, 11),
    ]);
  }

  test_localVariable_plusEquals_nonStringLiteral_parenthesized() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  for (final s in ['a']) {
    (buffer += s);
  }
}
''', [
      lint(64, 11),
    ]);
  }

  test_localVariable_plusEquals_stringLiteral() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  for (int i = 0; i < 10; i++) {
    buffer += 'a';
  }
}
''', [
      lint(69, 13),
    ]);
  }

  test_localVariable_whileLoop_plusEquals_stringLiteral() async {
    await assertDiagnostics(r'''
void foo() {
  var buffer = '';
  while (buffer.length < 10) {
    buffer += 'a';
  }
}
''', [
      lint(67, 13),
    ]);
  }

  test_loopVariable_plusEquals_nonStringLiteral() async {
    await assertNoDiagnostics(r'''
void foo() {
  for (final s in [ 'a', 'b']) {
    var buffer = '';
    buffer += s;
  }
}
''');
  }
}
