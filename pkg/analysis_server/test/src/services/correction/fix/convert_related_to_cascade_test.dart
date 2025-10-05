// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertRelatedToCascadeTest);
  });
}

@reflectiveTest
class ConvertRelatedToCascadeTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertRelatedToCascade;

  @override
  String get lintCode => LintNames.cascade_invocations;

  Future<void> test_declaration_method_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A();
  a.m();
  a.m();
}
''');
    await assertHasFix('''
class A {
  void m() {}
}
void f() {
  final a = A()
  ..m()
  ..m();
}
''', errorFilter: (error) => error.offset == testCode.indexOf('a.m();'));
  }

  Future<void> test_method_property_method() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.m();
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
  a..m()
  ..x = 1
  ..m();
}
''', errorFilter: (error) => error.offset == testCode.indexOf('a.x = 1'));
  }

  Future<void> test_multipleDeclaration_first_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A(), a2 = A();
  a.m();
}
''');
    await assertNoFix();
  }

  Future<void> test_multipleDeclaration_last_method() async {
    await resolveTestCode('''
class A {
  void m() {}
}
void f() {
  final a = A(), a2 = A();
  a2.m();
}
''');
    await assertNoFix();
  }

  Future<void> test_property_cascadeMethod_cascadeMethod() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}

void f(A a) {
  a.x = 1;
  a..m();
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
  ..m()
  ..m();
}
''', errorFilter: (error) => error.offset == testCode.indexOf('a..m();'));
  }

  Future<void> test_property_property_method_method_fisrt() async {
    await resolveTestCode('''
class A {
  void m(int _) {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2;
  a.m(1);
  a.m(2);
}
''');
    await assertHasFix('''
class A {
  void m(int _) {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2
  ..m(1)
  ..m(2);
}
''', errorFilter: (error) => error.offset == testCode.indexOf('a.m(1)'));
  }

  Future<void> test_property_property_method_method_last() async {
    await resolveTestCode('''
class A {
  void m(int _) {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2;
  a.m(1);
  a.m(2);
}
''');
    await assertHasFix('''
class A {
  void m(int _) {}
  int? x;
}

void f(A a) {
  a..x = 1
  ..x = 2
  ..m(1)
  ..m(2);
}
''', errorFilter: (error) => error.offset == testCode.indexOf('a.m(2)'));
  }

  Future<void> test_property_property_property() async {
    await resolveTestCode('''
class A {
  void m() {}
  int? x;
}
void f(A a) {
  a.x = 1;
  a.x = 2;
  a.x = 3;
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
  ..x = 3;
}
''', errorFilter: (error) => error.offset == testCode.indexOf('a.x = 2;'));
  }
}
