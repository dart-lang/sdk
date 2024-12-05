// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullableForFinalVariableDeclarationsTest);
  });
}

@reflectiveTest
class UnnecessaryNullableForFinalVariableDeclarationsTest extends LintRuleTest {
  @override
  String get lintRule =>
      LintNames.unnecessary_nullable_for_final_variable_declarations;

  test_list() async {
    await assertDiagnostics(r'''
f() {
  final [int a, num? c] = [0, 1];
  print('$a$c');
}
''', [
      lint(27, 1),
    ]);
  }

  test_list_dynamic_ok() async {
    await assertNoDiagnostics(r'''
f() {
  final [dynamic a, num c] = [0, 1];
  print('$a$c');
}
''');
  }

  test_nonNullableType_const() async {
    await assertNoDiagnostics(r'''
const int i = 1;
const dynamic j = 1;
''');
  }

  test_nonNullableType_field() async {
    await assertNoDiagnostics(r'''
class A {
  // ignore: unused_field
  final int _j = 1;
  final int j = 1;
  final dynamic k = 1;
  static final int l = 1;
  // ignore: unused_field
  static final int _l = 1;
}
''');
  }

  test_nonNullableType_field_extension() async {
    await assertNoDiagnostics(r'''
extension E on Object {
  // ignore: unused_field
  static final int _j = 1;
  static final int j = 1;
  static final dynamic k = 1;
}
''');
  }

  test_nonNullableType_topLevel() async {
    await assertNoDiagnostics(r'''
final int i = 1;
// ignore: unused_element
final int _j = 1;
''');
  }

  test_nonNullableType_variable() async {
    await assertNoDiagnostics(r'''
f() {
  final int _j = 1;
  final int j = 1;
  final dynamic k = 1;
}
''');
  }

  test_nullableType_field() async {
    await assertDiagnostics(r'''
class A {
  // ignore: unused_field
  final int? _i = 1;
  final int? i = 1;
  static final int? j = 1;
}
''', [
      lint(49, 2),
      lint(97, 1),
    ]);
  }

  test_nullableType_field_extension() async {
    await assertDiagnostics(r'''
extension E on Object {
  // ignore: unused_field
  static final int? _e = 1;
  static final int? e = 1;
}
''', [
      lint(70, 2),
      lint(98, 1),
    ]);
  }

  test_nullableType_topLevel() async {
    await assertDiagnostics(r'''
// ignore: unused_element
final int? _i = 1;
final int? i = 1;
const int? ic = 1;
''', [
      lint(37, 2),
      lint(56, 1),
      lint(74, 2),
    ]);
  }

  test_nullableType_variable() async {
    await assertDiagnostics(r'''
f() {
  final int? _i = 1;
  final int? i = 1;
}
''', [
      lint(19, 2),
      lint(40, 1),
    ]);
  }

  test_record() async {
    await assertDiagnostics(r'''
f() {
  final (List<int>? a, num? c) = ([], 1);
  print('$a$c');
}
''', [
      lint(26, 1),
      lint(34, 1),
    ]);
  }
}
