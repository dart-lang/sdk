// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ChangeToStaticAccessTest);
  });
}

@reflectiveTest
class ChangeToStaticAccessTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CHANGE_TO_STATIC_ACCESS;

  Future<void> test_method() async {
    await resolveTestCode('''
class A {
  static foo() {}
}
void f(A a) {
  a.foo();
}
''');
    await assertHasFix('''
class A {
  static foo() {}
}
void f(A a) {
  A.foo();
}
''');
  }

  Future<void> test_method_extension() async {
    await resolveTestCode('''
extension E on int {
  static void foo() {}
}
void f() {
  0.foo();
}
''');
    await assertHasFix('''
extension E on int {
  static void foo() {}
}
void f() {
  E.foo();
}
''');
  }

  Future<void> test_method_importType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static foo() {}
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'package:test/a.dart';

class B extends A {}
''');
    await resolveTestCode('''
import 'package:test/b.dart';

void f(B b) {
  b.foo();
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

void f(B b) {
  A.foo();
}
''');
  }

  Future<void> test_method_prefixLibrary() async {
    await resolveTestCode('''
import 'dart:async' as pref;

void f(pref.Future f) {
  f.wait([]);
}
''');
    await assertHasFix('''
import 'dart:async' as pref;

void f(pref.Future f) {
  pref.Future.wait([]);
}
''');
  }

  Future<void> test_property() async {
    await resolveTestCode('''
class A {
  static get foo => 42;
}
void f(A a) {
  a.foo;
}
''');
    await assertHasFix('''
class A {
  static get foo => 42;
}
void f(A a) {
  A.foo;
}
''');
  }

  @failingTest
  Future<void> test_property_extension() async {
    await resolveTestCode('''
extension E on int {
  static int get foo => 42;
}
void f() {
  0.foo;
}
''');
    await assertHasFix('''
extension E on int {
  static int get foo => 42;
}
void f() {
  E.foo;
}
''');
  }

  Future<void> test_property_importType() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static get foo => null;
}
''');
    newFile('$testPackageLibPath/b.dart', r'''
import 'package:test/a.dart';

class B extends A {}
''');
    await resolveTestCode('''
import 'package:test/b.dart';

void f(B b) {
  b.foo;
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart';

void f(B b) {
  A.foo;
}
''');
  }
}
