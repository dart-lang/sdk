// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToCascadeTest);
  });
}

@reflectiveTest
class ConvertToCascadeTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_CASCADE;

  @override
  String get lintCode => LintNames.cascade_invocations;

  Future<void> test_cascade_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2;
  a..m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2
  ..m();
}
''');
  }

  Future<void> test_method_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.m();
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..m()
  ..m();
}
''');
  }

  Future<void> test_method_property() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.m();
  a.x = 1;
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..m()
  ..x = 1;
}
''');
  }

  Future<void> test_property_cascade() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a.x = 1;
  a..m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..m();
}
''');
  }

  Future<void> test_property_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.x = 1;
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..x = 1
  ..m();
}
''');
  }

  Future<void> test_property_property() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.x = 1;
  a.x = 2;
}
''');
    await assertHasFix('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a..x = 1
  ..x = 2;
}
''');
  }
}
