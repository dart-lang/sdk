// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryPrefixTest);
  });
}

@reflectiveTest
class ImportLibraryPrefixTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_PREFIX;

  Future<void> test_withAnnotation() async {
    newFile('$testPackageLibPath/a.dart', '''
class MyAnnotation {
  const MyAnnotation();
}
''');
    await resolveTestCode('''
// ignore: unused_import
import 'a.dart' as prefix;

@MyAnnotation()
class B {}
''');
    await assertHasFix('''
// ignore: unused_import
import 'a.dart' as prefix;

@prefix.MyAnnotation()
class B {}
''');
  }

  Future<void> test_withClass() async {
    await resolveTestCode('''
import 'dart:collection' as prefix;

void f(prefix.HashMap a, HashMap b) {}
''');
    await assertHasFix('''
import 'dart:collection' as prefix;

void f(prefix.HashMap a, prefix.HashMap b) {}
''');
  }

  Future<void> test_withExtension() async {
    newFile('$testPackageLibPath/a.dart', '''
extension E on int {
  static int foo() => 0;
}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

void f() {
  prefix.E.foo();
  E.foo();
}
''');
    await assertHasFix('''
import 'a.dart' as prefix;

void f() {
  prefix.E.foo();
  prefix.E.foo();
}
''');
  }

  Future<void> test_withExtensionType() async {
    newFile('$testPackageLibPath/a.dart', '''
extension type ET(int it) {}
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

void f() {
  prefix.ET(7);
  ET(7);
}
''');
    await assertHasFix('''
import 'a.dart' as prefix;

void f() {
  prefix.ET(7);
  prefix.ET(7);
}
''');
  }

  Future<void> test_withTopLevelVariable() async {
    await resolveTestCode('''
import 'dart:math' as prefix;

void f() {
  prefix.e;
  pi;
}
''');
    await assertHasFix('''
import 'dart:math' as prefix;

void f() {
  prefix.e;
  prefix.pi;
}
''');
  }

  Future<void> test_withTypedef() async {
    newFile('$testPackageLibPath/a.dart', '''
typedef T = int;
''');
    await resolveTestCode('''
import 'a.dart' as prefix;

void f(num n) {
  n is prefix.T;
  n is T;
}
''');
    await assertHasFix('''
import 'a.dart' as prefix;

void f(num n) {
  n is prefix.T;
  n is prefix.T;
}
''');
  }
}
