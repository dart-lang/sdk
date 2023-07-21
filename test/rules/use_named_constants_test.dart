// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseNamedConstantsTest);
  });
}

@reflectiveTest
class UseNamedConstantsTest extends LintRuleTest {
  @override
  String get lintRule => 'use_named_constants';

  /// https://github.com/dart-lang/linter/issues/4201
  test_constantPattern_ifCase() async {
    await assertDiagnostics(r'''
class A {
  const A(this.value);
  final int value;

  static const zero = A(0);
}

void f(A a) {
  if (a case const A(0)) {}
}
''', [
      lint(117, 4),
    ]);
  }

  /// https://github.com/dart-lang/linter/issues/4201
  test_constantPattern_switch() async {
    await assertDiagnostics(r'''
class A {
  const A(this.value);
  final int value;

  static const zero = A(0);
  static const one = A(1);
}

void f(A a) {
  switch (a) {
    case const A(1):
  }
}
''', [
      lint(155, 4),
    ]);
  }

  test_duplicate_inDefinition() async {
    await assertNoDiagnostics(r'''
class A {
  const A(int value);
  static const zero = A(0);
  static const zeroAgain = A(0);
}
''');
  }

  test_reconstructed_sameAsPrivateName() async {
    await assertDiagnostics(r'''
void f() {
  const A(1);
}
class A {
  const A(int value);
  // ignore: unused_field
  static const _zero = A(0);
}
''', [
      lint(13, 10),
    ]);
  }

  test_reconstructed_sameAsPublicName_explicitConst() async {
    await assertDiagnostics(r'''
void f() {
  const A(0);
}
class A {
  const A(int value);
  static const zero = A(0);
}
''', [
      lint(13, 10),
    ]);
  }

  test_reconstructed_sameAsPublicName_implicitConst() async {
    await assertDiagnostics(r'''
void f() {
  const a = A(0);
}
class A {
  const A(int value);
  static const zero = A(0);
}
''', [
      lint(23, 4),
    ]);
  }

  test_usesNamed() async {
    await assertNoDiagnostics(r'''
void f() {
  A.zero;
}
class A {
  const A(int value);
  static const zero = A(0);
}
''');
  }
}
