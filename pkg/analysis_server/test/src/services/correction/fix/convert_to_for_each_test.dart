// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToForEachTest);
  });
}

@reflectiveTest
class ConvertToForEachTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_FOR_EACH;

  @override
  String get lintCode => LintNames.prefer_foreach;

  Future<void> test_instanceMethod() async {
    await resolveTestCode('''
class C {
  void m(int v) {}
}

void f(List<int> list) {
  for (var v in list) {
    C().m(v);
  }
}
''');
    await assertHasFix('''
class C {
  void m(int v) {}
}

void f(List<int> list) {
  list.forEach(C().m);
}
''');
  }

  Future<void> test_staticMethod() async {
    await resolveTestCode('''
class C {
  static void m(int v) {}
}

void f(List<int> list) {
  for (var v in list) {
    C.m(v);
  }
}
''');
    await assertHasFix('''
class C {
  static void m(int v) {}
}

void f(List<int> list) {
  list.forEach(C.m);
}
''');
  }

  Future<void> test_topLevel() async {
    await resolveTestCode('''
void g(int v) {}

void f(List<int> list) {
  for (var v in list) {
    g(v);
  }
}
''');
    await assertHasFix('''
void g(int v) {}

void f(List<int> list) {
  list.forEach(g);
}
''');
  }
}
