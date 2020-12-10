// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddNullCheckTest);
  });
}

@reflectiveTest
class AddNullCheckTest extends FixProcessorTest with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.ADD_NULL_CHECK;

  Future<void> test_argument() async {
    await resolveTestCode('''
void f(int x) {}
void g(int? y) {
  f(y);
}
''');
    await assertHasFix('''
void f(int x) {}
void g(int? y) {
  f(y!);
}
''');
  }

  Future<void> test_argument_differByMoreThanNullability() async {
    await resolveTestCode('''
void f(int x) {}
void g(String y) {
  f(y);
}
''');
    await assertNoFix();
  }

  Future<void> test_assignment() async {
    await resolveTestCode('''
void f(int x, int? y) {
  x = y;
}
''');
    await assertHasFix('''
void f(int x, int? y) {
  x = y!;
}
''');
  }

  Future<void>
      test_assignment_differByMoreThanNullability_nonNullableRight() async {
    await resolveTestCode('''
void f(int x, String y) {
  x = y;
}
''');
    await assertNoFix();
  }

  Future<void>
      test_assignment_differByMoreThanNullability_nullableRight() async {
    await resolveTestCode('''
void f(int x, String? y) {
  x = y;
}
''');
    await assertNoFix();
  }

  Future<void> test_assignment_needsParens() async {
    await resolveTestCode('''
void f(A x) {
  x = x + x;
}
class A {
  A? operator +(A a) => null;
}
''');
    await assertHasFix('''
void f(A x) {
  x = (x + x)!;
}
class A {
  A? operator +(A a) => null;
}
''');
  }

  Future<void> test_indexExpression() async {
    await resolveTestCode('''
void f (List<String>? args) {
  print(args[0]);
}
''');
    await assertHasFix('''
void f (List<String>? args) {
  print(args![0]);
}
''');
  }

  Future<void> test_initializer() async {
    await resolveTestCode('''
void f(int? x) {
  int y = x;
  print(y);
}
''');
    await assertHasFix('''
void f(int? x) {
  int y = x!;
  print(y);
}
''');
  }

  Future<void> test_initializer_differByMoreThanNullability() async {
    await resolveTestCode('''
void f(String x) {
  int y = x;
  print(y);
}
''');
    await assertNoFix();
  }
}
