// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoopPrimitiveOperationsTest);
  });
}

@reflectiveTest
class NoopPrimitiveOperationsTest extends LintRuleTest {
  @override
  String get lintRule => 'noop_primitive_operations';

  test_double_toDouble() async {
    await assertDiagnostics(r'''
void f(double x) {
  x.toDouble();
}
''', [
      lint(23, 8),
    ]);
  }

  test_int_ceil() async {
    await assertDiagnostics(r'''
void f(int x) {
  x.ceil();
}
''', [
      lint(20, 4),
    ]);
  }

  test_int_floor() async {
    await assertDiagnostics(r'''
void f(int x) {
  x.floor();
}
''', [
      lint(20, 5),
    ]);
  }

  test_int_round() async {
    await assertDiagnostics(r'''
void f(int x) {
  x.round();
}
''', [
      lint(20, 5),
    ]);
  }

  test_int_toInt() async {
    await assertDiagnostics(r'''
void f(int x) {
  x.toInt();
}
''', [
      lint(20, 5),
    ]);
  }

  test_int_truncate() async {
    await assertDiagnostics(r'''
void f(int x) {
  x.truncate();
}
''', [
      lint(20, 8),
    ]);
  }

  test_interpolation_object_toString() async {
    await assertDiagnostics(r'''
void f() {
  '${1.toString()}';
}
''', [
      lint(18, 8),
    ]);
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
    await assertDiagnostics(r'''
void f() {
  print(null.toString());
}
''', [
      lint(24, 8),
    ]);
  }

  test_print_object_toString() async {
    await assertDiagnostics(r'''
void f() {
  print(1.toString());
}
''', [
      lint(21, 8),
    ]);
  }

  test_print_stringLiteral() async {
    await assertNoDiagnostics(r'''
onPrint() {
  print(''); // OK
}
''');
  }

  test_string_adjacentBlankString() async {
    await assertDiagnostics(r'''
void f(String x) {
  x = 'hello\n' 'world\n' '';
}
''', [
      lint(45, 2),
    ]);
  }

  test_string_nullable_toString() async {
    await assertNoDiagnostics(r'''
void f(String? x) {
  x.toString();
}
''');
  }

  test_string_toString() async {
    await assertDiagnostics(r'''
void f(String x) {
  x.toString();
}
''', [
      lint(23, 8),
    ]);
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
