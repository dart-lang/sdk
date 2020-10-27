// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveComparisonTest);
  });
}

@reflectiveTest
class RemoveComparisonTest extends FixProcessorTest with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.REMOVE_COMPARISON;

  Future<void> test_assertInitializer_first() async {
    await resolveTestUnit('''
class C {
  String t;
  C(String s) : assert(s != null), t = s;
}
''');
    await assertHasFix('''
class C {
  String t;
  C(String s) : t = s;
}
''');
  }

  Future<void> test_assertInitializer_last() async {
    await resolveTestUnit('''
class C {
  String t;
  C(String s) : t = s, assert(s != null);
}
''');
    await assertHasFix('''
class C {
  String t;
  C(String s) : t = s;
}
''');
  }

  Future<void> test_assertInitializer_middle() async {
    await resolveTestUnit('''
class C {
  String t;
  String u;
  C(String s) : t = s, assert(s != null), u = s;
}
''');
    await assertHasFix('''
class C {
  String t;
  String u;
  C(String s) : t = s, u = s;
}
''');
  }

  Future<void> test_assertInitializer_only() async {
    await resolveTestUnit('''
class C {
  C(String s) : assert(s != null);
}
''');
    await assertHasFix('''
class C {
  C(String s);
}
''');
  }

  Future<void> test_assertStatement() async {
    await resolveTestUnit('''
void f(String s) {
  assert(s != null);
  print(s);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s);
}
''');
  }

  Future<void> test_binaryExpression_and_left() async {
    await resolveTestUnit('''
void f(String s) {
  print(s != null && s.isNotEmpty);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isNotEmpty);
}
''');
  }

  Future<void> test_binaryExpression_and_right() async {
    await resolveTestUnit('''
void f(String s) {
  print(s.isNotEmpty && s != null);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isNotEmpty);
}
''');
  }

  Future<void> test_binaryExpression_or_left() async {
    await resolveTestUnit('''
void f(String s) {
  print(s == null || s.isEmpty);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isEmpty);
}
''');
  }

  Future<void> test_binaryExpression_or_right() async {
    await resolveTestUnit('''
void f(String s) {
  print(s.isEmpty || s == null);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s.isEmpty);
}
''');
  }

  Future<void> test_ifStatement() async {
    await resolveTestUnit('''
void f(String s) {
  if (s != null) {
    print(s);
  }
}
''');
    await assertHasFix('''
void f(String s) {
  print(s);
}
''');
  }
}
