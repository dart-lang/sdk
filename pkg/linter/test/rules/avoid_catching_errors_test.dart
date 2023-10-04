// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCatchingErrorsTest);
  });
}

@reflectiveTest
class AvoidCatchingErrorsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_catching_errors';

  test_doesNotSubclassError() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} on String catch (_) {}
}
''');
  }

  test_exactlyError() async {
    await assertDiagnostics(r'''
void f() {
  try {} on Error catch (_) {}
}
''', [
      lint(20, 21),
    ]);
  }

  test_exactlyException() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} on Exception catch (_) {}
}
''');
  }

  test_typeExtendsError() async {
    await assertDiagnostics(r'''
void f() {
  try {} on C {}
}

class C extends Error {}
class D extends C {}
''', [
      lint(20, 7),
    ]);
  }

  test_typeExtendsTypeThatExtendsError() async {
    await assertDiagnostics(r'''
void f() {
  try {} on D {}
}

class D extends C {}
class C extends Error {}
''', [
      lint(20, 7),
    ]);
  }

  test_typeExtendsTypeThatImplementsError() async {
    await assertDiagnostics(r'''
void f() {
  try {} on B catch (_) {}
}

abstract class A implements Error {}
abstract class B extends A {}
''', [
      lint(20, 17),
    ]);
  }

  test_typeImplementsError() async {
    await assertDiagnostics(r'''
void f() {
  try {} on A catch (_) {}
}

abstract class A implements Error {}
''', [
      lint(20, 17),
    ]);
  }
}
