// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCatchingErrorsTest);
  });
}

@reflectiveTest
class AvoidCatchingErrorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.avoid_catching_errors;

  test_doesNotSubclassError() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} on String catch (_) {}
}
''');
  }

  test_exactlyError() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {} [!on Error catch (_) {}!]
}
''');
  }

  test_exactlyException() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} on Exception catch (_) {}
}
''');
  }

  test_extensionTypeWrapsError() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(Error e) implements Object {}
void f() {
  try {} [!on E catch (_) {}!]
}
''');
  }

  test_extensionTypeWrapsSubclassOfError() async {
    await assertDiagnosticsFromMarkup(r'''
extension type E(ArgumentError e) implements Object {}
void f() {
  try {} [!on E catch (_) {}!]
}
''');
  }

  test_typeExtendsError() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {} [!on C {}!]
}

class C extends Error {}
class D extends C {}
''');
  }

  test_typeExtendsTypeThatExtendsError() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {} [!on D {}!]
}

class D extends C {}
class C extends Error {}
''');
  }

  test_typeExtendsTypeThatImplementsError() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {} [!on B catch (_) {}!]
}

abstract class A implements Error {}
abstract class B extends A {}
''');
  }

  test_typeImplementsError() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  try {} [!on A catch (_) {}!]
}

abstract class A implements Error {}
''');
  }
}
