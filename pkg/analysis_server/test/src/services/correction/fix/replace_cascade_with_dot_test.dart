// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceCascadeWithDotTest);
    defineReflectiveTests(ReplaceCascadeWithDotWithNullSafetyTest);
  });
}

@reflectiveTest
class ReplaceCascadeWithDotTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_CASCADE_WITH_DOT;

  @override
  String get lintCode =>
      LintNames.avoid_single_cascade_in_expression_statements;

  Future<void> test_assignment_index_normalCascade() async {
    await resolveTestUnit('''
void f(List<int> l) {
  l..[0] = 0;
}
''');
    await assertHasFix('''
void f(List<int> l) {
  l[0] = 0;
}
''');
  }

  Future<void> test_assignment_property_normalCascade() async {
    await resolveTestUnit('''
void f(C c) {
  c..s = 0;
}
class C {
  set s(int i) {}
}
''');
    await assertHasFix('''
void f(C c) {
  c.s = 0;
}
class C {
  set s(int i) {}
}
''');
  }

  Future<void> test_getter_normalCascade() async {
    await resolveTestUnit('''
void f(String s) {
  s..length;
}
''');
    await assertHasFix('''
void f(String s) {
  s.length;
}
''');
  }

  Future<void> test_index_normalCascade() async {
    await resolveTestUnit('''
void f(String s) {
  s..[0];
}
''');
    await assertHasFix('''
void f(String s) {
  s[0];
}
''');
  }

  Future<void> test_method_normalCascade() async {
    await resolveTestUnit('''
void f(String s) {
  s..substring(0, 3);
}
''');
    await assertHasFix('''
void f(String s) {
  s.substring(0, 3);
}
''');
  }
}

@reflectiveTest
class ReplaceCascadeWithDotWithNullSafetyTest
    extends ReplaceCascadeWithDotTest {
  @override
  List<String> get experiments => [EnableString.non_nullable];

  Future<void> test_assignment_index_nullAwareCascade() async {
    await resolveTestUnit('''
void f(List<int>? l) {
  l?..[0] = 0;
}
''');
    await assertHasFix('''
void f(List<int>? l) {
  l?[0] = 0;
}
''');
  }

  Future<void> test_assignment_property_nullAwareCascade() async {
    await resolveTestUnit('''
void f(C? c) {
  c?..s = 0;
}
class C {
  set s(int i) {}
}
''');
    await assertHasFix('''
void f(C? c) {
  c?.s = 0;
}
class C {
  set s(int i) {}
}
''');
  }

  Future<void> test_getter_nullAwareCascade() async {
    await resolveTestUnit('''
void f(String? s) {
  s?..length;
}
''');
    await assertHasFix('''
void f(String? s) {
  s?.length;
}
''');
  }

  Future<void> test_index_nullAwareCascade() async {
    await resolveTestUnit('''
void f(String? s) {
  s?..[0];
}
''');
    await assertHasFix('''
void f(String? s) {
  s?[0];
}
''');
  }

  Future<void> test_method_nullAwareCascade() async {
    await resolveTestUnit('''
void f(String? s) {
  s?..substring(0, 3);
}
''');
    await assertHasFix('''
void f(String? s) {
  s?.substring(0, 3);
}
''');
  }
}
