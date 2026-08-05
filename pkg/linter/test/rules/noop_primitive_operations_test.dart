// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoopPrimitiveOperationsTest);
  });
}

@reflectiveTest
class NoopPrimitiveOperationsTest extends LintRuleTest {
  @override
  String get lintRule => LintNames.noop_primitive_operations;

  test_double_toDouble() async {
    await assertDiagnosticsFromMarkup(r'''
void f(double x) {
  x.[!toDouble!]();
}
''');
  }

  test_int_ceil() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int x) {
  x.[!ceil!]();
}
''');
  }

  test_int_floor() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int x) {
  x.[!floor!]();
}
''');
  }

  test_int_round() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int x) {
  x.[!round!]();
}
''');
  }

  test_int_toInt() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int x) {
  x.[!toInt!]();
}
''');
  }

  test_int_truncate() async {
    await assertDiagnosticsFromMarkup(r'''
void f(int x) {
  x.[!truncate!]();
}
''');
  }

  test_interpolation_object_toString() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  '${1.[!toString!]()}';
}
''');
  }

  test_interpolation_super_toString() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {
    '${super.toString()}';
  }
}
''');
  }

  test_print_null_toString() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  print(null.[!toString!]());
}
''');
  }

  test_print_object_toString() async {
    await assertDiagnosticsFromMarkup(r'''
void f() {
  print(1.[!toString!]());
}
''');
  }

  test_print_stringLiteral() async {
    await assertNoDiagnostics(r'''
onPrint() {
  print(''); // OK
}
''');
  }

  test_string_adjacentBlankString_lintInMiddle() async {
    await assertDiagnosticsFromMarkup(r'''
void f(String x) {
  x = 'hello\n' [!''!] 'world\n';
}
''');
  }

  test_string_adjacentBlankString_okAtEnd() async {
    await assertNoDiagnostics(r'''
void f(String x) {
  x = 'hello\n' 'world\n' '';
}
''');
  }

  test_string_adjacentBlankString_okAtStart() async {
    await assertNoDiagnostics(r'''
void f(String x) {
  x = '' 'hello\n' 'world\n';
}
''');
  }

  test_string_nullable_toString() async {
    await assertNoDiagnostics(r'''
void f(String? x) {
  x.toString();
}
''');
  }

  test_string_toString() async {
    await assertDiagnosticsFromMarkup(r'''
void f(String x) {
  x.[!toString!]();
}
''');
  }

  test_super_toString() async {
    await assertNoDiagnostics(r'''
class C {
  void m() {
    super.toString();
  }
}
''');
  }

  test_unrelatedToStringFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  print(toString());
}

String toString() => '';
''');
  }
}
