// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

void main() {
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
    await assertDiagnosticsFromMarkup(r'''
f() {
  final [int a, num? [!c!]] = [0, 1];
  print('$a$c');
}
''');
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
    await assertDiagnosticsFromMarkup(r'''
class A {
  // ignore: unused_field
  final int? /*[0*/_i/*0]*/ = 1;
  final int? i = 1;
  static final int? /*[1*/j/*1]*/ = 1;
}
''');
  }

  test_nullableType_field_extension() async {
    await assertDiagnosticsFromMarkup(r'''
extension E on Object {
  // ignore: unused_field
  static final int? /*[0*/_e/*0]*/ = 1;
  static final int? /*[1*/e/*1]*/ = 1;
}
''');
  }

  test_nullableType_topLevel() async {
    await assertDiagnosticsFromMarkup(r'''
// ignore: unused_element
final int? /*[0*/_i/*0]*/ = 1;
final int? /*[1*/i/*1]*/ = 1;
const int? /*[2*/ic/*2]*/ = 1;
''');
  }

  test_nullableType_variable() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  final int? /*[0*/_i/*0]*/ = 1;
  final int? /*[1*/i/*1]*/ = 1;
}
''');
  }

  test_record() async {
    await assertDiagnosticsFromMarkup(r'''
f() {
  final (List<int>? /*[0*/a/*0]*/, num? /*[1*/c/*1]*/) = ([], 1);
  print('$a$c');
}
''');
  }
}
