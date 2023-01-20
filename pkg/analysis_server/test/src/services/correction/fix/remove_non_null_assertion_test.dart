// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveNonNullAssertionBulkTest);
    defineReflectiveTests(RemoveNonNullAssertionTest);
  });
}

@reflectiveTest
class RemoveNonNullAssertionBulkTest extends BulkFixProcessorTest {
  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(String a) {
  print(a!!);
}
''');
    await assertHasFix('''
void f(String a) {
  print(a);
}
''');
  }
}

@reflectiveTest
class RemoveNonNullAssertionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_NON_NULL_ASSERTION;

  Future<void> test_nonNullable() async {
    await resolveTestCode('''
void f(String a) {
  print(a!);
}
''');
    await assertHasFix('''
void f(String a) {
  print(a);
}
''');
  }

  Future<void> test_nonNullableCasePattern() async {
    await resolveTestCode('''
void f() {
  List<String> row = ['h', 'e', 'l'];
  switch (row) {
    case ['user', var name!]:
    print(name);
  }
}
''');
    await assertHasFix('''
void f() {
  List<String> row = ['h', 'e', 'l'];
  switch (row) {
    case ['user', var name]:
    print(name);
  }
}
''');
  }

  Future<void> test_nonNullablePattern() async {
    await resolveTestCode('''
void f() {
  (int, int?) p = (1, 2);
  var (x!, y!) = p;
  print(x);
  print(y);
}
''');
    await assertHasFix('''
void f() {
  (int, int?) p = (1, 2);
  var (x, y!) = p;
  print(x);
  print(y);
}
''');
  }
}
