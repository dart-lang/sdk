// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryHideTest);
  });
}

@reflectiveTest
class ImportLibraryHideTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_COMBINATOR;

  Future<void> test_extension_aliased_hidden_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib hide E;

void f(String s, lib.C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib;

void f(String s, lib.C c) {
  s.m;
}
''');
  }

  Future<void> test_extension_hidden_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_extension_hidden_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m();
}
''');
  }

  Future<void> test_extension_hidden_operator() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  String operator -(String other) => this;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s - '2';
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s - '2';
}
''');
  }

  Future<void> test_extension_hidden_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  set m(int v) {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s.m = 2;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m = 2;
}
''');
  }

  Future<void> test_fromPackageLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide B;
void f() {
  A? a;
  B b;
  print('$a $b');
}
''');
    await assertHasFix(r'''
import 'lib.dart';
void f() {
  A? a;
  B b;
  print('$a $b');
}
''');
  }

  Future<void> test_fromSdkLibrary() async {
    await resolveTestCode(r'''
import 'dart:collection' hide LinkedHashMap;
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('$s $f');
}
''');
    await assertHasFix(r'''
import 'dart:collection';
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('$s $f');
}
''');
  }

  Future<void> test_multipleHide_extension_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
class D {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E, D;

void f(String s, C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' hide D;

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_override_samePackage() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on int {
  String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide E;
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart';
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
  }

  Future<void> test_static_samePackage() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide E;
void f(A a) {
  print('$a ${E.m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart';
void f(A a) {
  print('$a ${E.m()}');
}
''');
  }
}
