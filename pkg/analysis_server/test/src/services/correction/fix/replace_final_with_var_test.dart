// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceFinalWithVarBulkTest);
    defineReflectiveTests(ReplaceFinalWithVarTest);
    defineReflectiveTests(ReplaceFinalWithVarTypedRemoveTest);
  });
}

@reflectiveTest
class ReplaceFinalWithVarBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_final;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  final int a = 1;
  final b = 1;
  final c = 1;
  print(a + b + c);
}
''');
    await assertHasFix('''
void f() {
  int a = 1;
  var b = 1;
  var c = 1;
  print(a + b + c);
}
''');
  }
}

@reflectiveTest
class ReplaceFinalWithVarTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceFinalWithVar;

  @override
  String get lintCode => LintNames.unnecessary_final;

  Future<void> test_forIn_pattern() async {
    await resolveTestCode(r'''
void foo(Map<String, String> map) {
  for (final MapEntry(:key, :value) in map.entries) {
    print('$key: $value');
  }
}
''');
    await assertHasFix(r'''
void foo(Map<String, String> map) {
  for (var MapEntry(:key, :value) in map.entries) {
    print('$key: $value');
  }
}
''');
  }

  Future<void> test_function_forLoop() async {
    await resolveTestCode('''
void f(List<int> values) {
  // ignore:unused_local_variable
  for (final v in values) {}
}
''');
    await assertHasFix('''
void f(List<int> values) {
  // ignore:unused_local_variable
  for (var v in values) {}
}
''');
  }

  Future<void> test_function_variableTyped() async {
    await resolveTestCode('''
void f() {
  final int a = 1;
  print(a);
}
''');
    await assertNoFix();
  }

  Future<void> test_if_case_pattern() async {
    await resolveTestCode(r'''
f() {
  if (0 case final a){
    print(a);
  }
}
''');
    await assertHasFix(r'''
f() {
  if (0 case var a){
    print(a);
  }
}
''');
  }

  Future<void> test_ifCase_pattern() async {
    await resolveTestCode(r'''
void foo(Map<String, String> map) {
  if (map case final m) {
    print('Map has ${m.length} entries');
  }
}
''');
    await assertHasFix(r'''
void foo(Map<String, String> map) {
  if (map case var m) {
    print('Map has ${m.length} entries');
  }
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/51864
  Future<void> test_listPattern_assignment() async {
    await resolveTestCode('''
f() {
  final [a] = [1];
  print(a);
}
''');
    await assertHasFix('''
f() {
  var [a] = [1];
  print(a);
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/51864
  @FailingTest(reason: 'Not supported')
  Future<void> test_listPattern_ifCase() async {
    // Note that the simpler case is also unsupported:
    // final int x = 0;

    // Switch cases are similarly unsupported.
    await resolveTestCode('''
f(Object o) {
  if (o case [final int x]) print(x);
}
''');
    await assertHasFix('''
f(Object o) {
  if (o case [int x]) print(x);
}
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
void f() {
  final a = 1;
  print(a);
}
''');
    await assertHasFix('''
void f() {
  var a = 1;
  print(a);
}
''');
  }

  Future<void> test_pattern() async {
    await resolveTestCode('''
void foo(int a) {
  final int(:isEven) = a;
  print(isEven);
}
''');
    await assertHasFix('''
void foo(int a) {
  var int(:isEven) = a;
  print(isEven);
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/51864
  Future<void> test_recordPattern_assignment() async {
    await resolveTestCode(r'''
f() {
  final (a, b) = (1, 2);
  print('$a$b');
}
''');
    await assertHasFix(r'''
f() {
  var (a, b) = (1, 2);
  print('$a$b');
}
''');
  }
}

@reflectiveTest
class ReplaceFinalWithVarTypedRemoveTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeUnnecessaryFinal;

  @override
  String get lintCode => LintNames.unnecessary_final;

  Future<void> test_final_type() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (final int value in values) {
    value;
  }
}
''');
    await assertHasFix(r'''
void f(List<int> values) {
  for (int value in values) {
    value;
  }
}
''');
  }

  Future<void> test_function_variableTyped() async {
    await resolveTestCode('''
void f() {
  final int a = 1;
  print(a);
}
''');
    await assertHasFix('''
void f() {
  int a = 1;
  print(a);
}
''');
  }

  Future<void> test_function_variableUntyped() async {
    await resolveTestCode('''
void f() {
  final a = 1;
  print(a);
}
''');
    await assertNoFix();
  }

  Future<void> test_ifCase_pattern() async {
    await resolveTestCode(r'''
void foo(Map<String, String> map) {
  if (map case final Map<String, String> m) {
    print('Map has ${m.length} entries');
  }
}
''');
    await assertHasFix(r'''
void foo(Map<String, String> map) {
  if (map case Map<String, String> m) {
    print('Map has ${m.length} entries');
  }
}
''');
  }
}
