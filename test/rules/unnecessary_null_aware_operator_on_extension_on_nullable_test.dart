// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
        UnnecessaryNullAwareOperatorOnExtensionOnNullableTest);
  });
}

@reflectiveTest
class UnnecessaryNullAwareOperatorOnExtensionOnNullableTest
    extends LintRuleTest {
  @override
  String get lintRule =>
      'unnecessary_null_aware_operator_on_extension_on_nullable';

  test_extensionOverride_getter() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  int get foo => 1;
}
void f(int? i) {
  E(i).foo;
}
''');
  }

  test_extensionOverride_getter_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  int get foo => 1;
}
void f(int? i) {
  E(i)?.foo;
}
''', [
      lint(67, 2),
    ]);
  }

  test_extensionOverride_indexAssignment() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  void operator []=(int i, String v) {}
}
void f(int? i) {
  E(i)[0] = '';
}
''');
  }

  test_extensionOverride_indexAssignment_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  void operator []=(int i, String v) {}
}
void f(int? i) {
  E(i)?[0] = '';
}
''', [
      lint(87, 1),
    ]);
  }

  test_extensionOverride_indexOperator() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  String operator [](int i) => '';
}
void f(int? i) {
  E(i)[0];
}
''');
  }

  test_extensionOverride_indexOperator_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  String operator [](int i) => '';
}
void f(int? i) {
  E(i)?[0];
}
''', [
      lint(82, 1),
    ]);
  }

  test_extensionOverride_methodCall() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  int m() => 1;
}
void f(int? i) {
  E(i).m();
}
''');
  }

  test_extensionOverride_methodCall_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  int m() => 1;
}
void f(int? i) {
  E(i)?.m();
}
''', [
      lint(63, 2),
    ]);
  }

  test_extensionOverride_setter() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  void set foo(int v) {}
}
void f(int? i) {
  E(i).foo = 1;
}
''');
  }

  test_extensionOverride_setter_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  void set foo(int v) {}
}
void f(int? i) {
  E(i)?.foo = 1;
}
''', [
      lint(72, 2),
    ]);
  }

  test_getter() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  int get foo => 1;
}
void f(int? i) {
  i.foo;
}
''');
  }

  test_getter_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  int get foo => 1;
}
void f(int? i) {
  i?.foo;
}
''', [
      lint(64, 2),
    ]);
  }

  test_indexAssignment() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  void operator []=(int i, String v) {}
}
void f(int? i) {
  i[0] = '';
}
''');
  }

  test_indexAssignment_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  void operator []=(int i, String v) {}
}
void f(int? i) {
  i?[0] = '';
}
''', [
      lint(84, 1),
    ]);
  }

  test_indexOperator() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  String operator [](int i) => '';
}
void f(int? i) {
  i[0];
}
''');
  }

  test_indexOperator_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  String operator [](int i) => '';
}
void f(int? i) {
  i?[0];
}
''', [
      lint(79, 1),
    ]);
  }

  test_methodCall() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  int m() => 1;
}
void f(int? i) {
  i.m();
}
''');
  }

  test_methodCall_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  int m() => 1;
}
void f(int? i) {
  i?.m();
}
''', [
      lint(60, 2),
    ]);
  }

  test_setter() async {
    await assertNoDiagnostics(r'''
extension E on int? {
  void set foo(int v) {}
}
void f(int? i) {
  i.foo = 1;
}
''');
  }

  test_setter_nullAware() async {
    await assertDiagnostics(r'''
extension E on int? {
  void set foo(int v) {}
}
void f(int? i) {
  i?.foo = 1;
}
''', [
      lint(69, 2),
    ]);
  }
}
