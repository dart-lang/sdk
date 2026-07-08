// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferNullAwareOperatorsTest);
  });
}

@reflectiveTest
class PreferNullAwareOperatorsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.prefer_null_aware_operators;

  test_identifierEqualEqualNull_null_elseBinaryExpression() async {
    await assertNoDiagnostics(r'''
void f(A? a) {
  a == null ? null : a.b + 10;
}

abstract class A {
  int get b;
}
''');
  }

  test_identifierEqualEqualNull_null_elseMethodCall() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!a == null ? null : a.b()!];
}

abstract class A {
  void b();
}
''');
  }

  test_identifierEqualEqualNull_null_elsePrefixedIdentifier() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!a == null ? null : a.b!];
}

abstract class A {
  int get b;
}
''');
  }

  test_identifierEqualEqualNull_null_elsePropertyAccess() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!a == null ? null : a.b.c!];
}

abstract class A {
  A get b;
  int get c;
}
''');
  }

  test_identifierEqualEqualNull_unrelatedBranch() async {
    // This is covered by another rule.
    await assertNoDiagnostics(r'''
void f(int? a, int b) {
  a == null ? b : a;
}
''');
  }

  test_identifierEqualEqualNull_unrelatedBranches() async {
    await assertNoDiagnostics(r'''
void f(int? a, int b) {
  a == null ? b.isEven : null;
}
''');
  }

  test_identifierNotEqualNull_prefixedIdentifier_elseNull() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!a != null ? a.b : null!];
}

abstract class A {
  int get b;
}
''');
  }

  test_identifierNotEqualNull_prefixedIdentifier_null() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!a != null ? a.b : null!];
}

abstract class A {
  int get b;
}
''');
  }

  test_nullEqualEqualIdentifier_null_elseMethodInvocation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!null == a ? null : a.b()!];
}

abstract class A {
  void b();
}
''');
  }

  test_nullEqualEqualIdentifier_null_elsePrefixedIdentifier() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!null == a ? null : a.b!];
}

abstract class A {
  int get b;
}
''');
  }

  test_nullEqualEqualPrefixedIdentifier_null_elsePropertyAccess() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A a) {
  [!null == a.b ? null : a.b!.c!];
}

abstract class A {
  A? get b;
  int get c;
}
''');
  }

  test_nullNotEqualIdentifier_prefixedIdentifier_elseNull() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A? a) {
  [!null != a ? a.b : null!];
}

abstract class A {
  int get b;
}
''');
  }

  test_nullNotEqualPrefixedIdentifier_propertyAccess_elseNull() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A a) {
  [!null != a.b ? a.b!.c : null!];
}

abstract class A {
  A? get b;
  int get c;
}
''');
  }

  test_prefixedIdentifierEqualEqualNull_null_elseMethodInvocation() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A a) {
  [!a.b == null ? null : a.b!.c()!];
}

abstract class A {
  A? get b;
  void c();
}
''');
  }

  test_prefixedIdentifierEqualEqualNull_null_elsePropertyAccess() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A a) {
  [!a.b == null ? null : a.b!.c!];
}

abstract class A {
  A? get b;
  int get c;
}
''');
  }

  test_prefixedIdentifierNotEqualNull_prefixedIdentifier_elseNull() async {
    await assertNoDiagnostics(r'''
void f(A a) {
  a.b != null ? a.b : null;
}

abstract class A {
  int? get b;
}
''');
  }

  test_prefixedIdentifierNotEqualNull_propertyAccess_elseNull() async {
    await assertDiagnosticsFromMarkup(r'''
void f(A a) {
  [!a.b != null ? a.b!.c : null!];
}

abstract class A {
  A? get b;
  int get c;
}
''');
  }
}
