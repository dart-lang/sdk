// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferNullAwareMethodCallsTest);
  });
}

@reflectiveTest
class PreferNullAwareMethodCallsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_null_aware_method_calls;

  test_conditional_differentTargets() async {
    await assertNoDiagnostics(r'''
Function()? f1, f2;
void f() {
  f1 != null ? f2!() : null;
}
''');
  }

  test_conditional_propertyAccess_differentProperties() async {
    await assertNoDiagnostics(r'''
void f(dynamic p) {
  p.a != null ? p.m!() : null;
}
''');
  }

  test_conditional_propertyAccess_sameProperty() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p) {
  p.m != null ? [!p.m!()!] : null;
}
''');
  }

  test_conditional_sameTarget() async {
    await assertDiagnosticsFromMarkup(r'''
Function()? func;
void f() {
  func != null ? [!func!()!] : null;
}
''');
  }

  test_ifNotNull_propertyAccess_differentProperties() async {
    await assertNoDiagnostics(r'''
void f(dynamic p) {
  if (p.a != null) {
    p.m!();
  }
}
''');
  }

  test_ifNotNull_propertyAccess_sameProperty() async {
    await assertDiagnosticsFromMarkup(r'''
void f(dynamic p) {
  if (p.m != null) {
    [!p.m!()!];
  }
}
''');
  }

  test_ifNotNull_sameTarget_blockStatement() async {
    await assertDiagnosticsFromMarkup(r'''
Function()? func;
void f() {
  if (func != null) {
    [!func!()!];
  }
}
''');
  }

  test_ifNotNull_sameTarget_expressionStatement() async {
    await assertDiagnosticsFromMarkup(r'''
Function()? func;
void f() {
  if (func != null) [!func!()!];
}
''');
  }
}
