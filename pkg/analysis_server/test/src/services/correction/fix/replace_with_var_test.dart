// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithVarTest);
  });
}

@reflectiveTest
class ReplaceWithVarTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_VAR;

  @override
  String get lintCode => LintNames.omit_local_variable_types;

  Future<void> test_for() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (int i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (var i = 0; i < list.length; i++) {
    print(i);
  }
}
''');
  }

  Future<void> test_forEach() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (var i in list) {
    print(i);
  }
}
''');
  }

  Future<void> test_forEach_final() async {
    await resolveTestCode('''
void f(List<int> list) {
  for (final int i in list) {
    print(i);
  }
}
''');
    await assertHasFix('''
void f(List<int> list) {
  for (final i in list) {
    print(i);
  }
}
''');
  }

  Future<void> test_generic_instanceCreation_cascade() async {
    await resolveTestCode('''
Set f() {
  Set<String> s = Set<String>()..addAll([]);
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = Set<String>()..addAll([]);
  return s;
}
''');
  }

  Future<void> test_generic_instanceCreation_withArguments() async {
    await resolveTestCode('''
C<int> f() {
  C<int> c = C<int>();
  return c;
}
class C<T> {}
''');
    await assertHasFix('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_instanceCreation_withoutArguments() async {
    await resolveTestCode('''
C<int> f() {
  C<int> c = C();
  return c;
}
class C<T> {}
''');
    await assertHasFix('''
C<int> f() {
  var c = C<int>();
  return c;
}
class C<T> {}
''');
  }

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List f() {
  List<int> l = [];
  return l;
}
''');
    await assertHasFix('''
List f() {
  var l = <int>[];
  return l;
}
''');
  }

  Future<void> test_generic_listLiteral_const() async {
    await resolveTestCode('''
String f() {
  const List<String> values = const ['a'];
  return values[0];
}
''');
    await assertHasFix('''
String f() {
  const values = const <String>['a'];
  return values[0];
}
''');
  }

  Future<void> test_generic_mapLiteral() async {
    await resolveTestCode('''
Map f() {
  Map<String, int> m = {};
  return m;
}
''');
    await assertHasFix('''
Map f() {
  var m = <String, int>{};
  return m;
}
''');
  }

  Future<void> test_generic_mapLiteral_const() async {
    await resolveTestCode('''
Map f() {
  const Map<String, int> m = const {};
  return m;
}
''');
    await assertHasFix('''
Map f() {
  const m = const <String, int>{};
  return m;
}
''');
  }

  Future<void> test_generic_setLiteral() async {
    await resolveTestCode('''
Set f() {
  Set<int> s = {};
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <int>{};
  return s;
}
''');
  }

  Future<void> test_generic_setLiteral_ambiguous() async {
    await resolveTestCode('''
Set f() {
  Set s = {};
  return s;
}
''');
    await assertNoFix();
  }

  Future<void> test_generic_setLiteral_cascade() async {
    await resolveTestCode('''
Set f() {
  Set<String> s = {}..addAll([]);
  return s;
}
''');
    await assertHasFix('''
Set f() {
  var s = <String>{}..addAll([]);
  return s;
}
''');
  }

  Future<void> test_generic_setLiteral_const() async {
    await resolveTestCode('''
String f() {
  const Set<String> s = const {'a'};
  return s.first;
}
''');
    await assertHasFix('''
String f() {
  const s = const <String>{'a'};
  return s.first;
}
''');
  }

  Future<void> test_simple() async {
    await resolveTestCode('''
String f() {
  String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  var s = '';
  return s;
}
''');
  }

  Future<void> test_simple_const() async {
    await resolveTestCode('''
String f() {
  const String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  const s = '';
  return s;
}
''');
  }

  Future<void> test_simple_final() async {
    await resolveTestCode('''
String f() {
  final String s = '';
  return s;
}
''');
    await assertHasFix('''
String f() {
  final s = '';
  return s;
}
''');
  }
}
