// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryShowTest);
  });
}

@reflectiveTest
class ImportLibraryShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_SHOW;

  Future<void> test_override_samePackage() async {
    addSource('/home/test/lib/lib.dart', '''
class A {}
extension E on int {
  String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, E;
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
  }

  Future<void> test_package() async {
    addSource('/home/test/lib/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
main() {
  A a;
  B b;
  print('$a $b');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, B;
main() {
  A a;
  B b;
  print('$a $b');
}
''');
  }

  Future<void> test_sdk() async {
    await resolveTestCode(r'''
import 'dart:collection' show HashMap;
main() {
  HashMap s = null;
  LinkedHashMap f = null;
  print('$s $f');
}
''');
    await assertHasFix(r'''
import 'dart:collection' show HashMap, LinkedHashMap;
main() {
  HashMap s = null;
  LinkedHashMap f = null;
  print('$s $f');
}
''');
  }

  Future<void> test_static_samePackage() async {
    addSource('/home/test/lib/lib.dart', '''
class A {}
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
void f(A a) {
  print('$a ${E.m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, E;
void f(A a) {
  print('$a ${E.m()}');
}
''');
  }
}
