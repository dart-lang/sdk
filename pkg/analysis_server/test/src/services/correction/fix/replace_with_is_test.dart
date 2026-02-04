// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithIsTest);
  });
}

@reflectiveTest
class ReplaceWithIsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.replaceWithIs;

  @override
  String get lintCode => LintNames.unrelated_type_equality_checks;

  Future<void> test_is() async {
    await resolveTestCode('''
void f(num n) {
  if (n == String) {}
}
''');
    await assertHasFix('''
void f(num n) {
  if (n is String) {}
}
''');
  }

  Future<void> test_isNot() async {
    await resolveTestCode('''
void f(num n) {
  if (n != String) {}
}
''');
    await assertHasFix('''
void f(num n) {
  if (n is! String) {}
}
''');
  }

  Future<void> test_notTypeAnnotation() async {
    await resolveTestCode('''
void f(num n) {
  if (n != n.runtimeType) {}
}
''');
    await assertNoFix();
  }

  Future<void> test_prefixed() async {
    await resolveTestCode('''
import 'dart:async' as async;

void f(num n) {
  if (n != async.Future) {}
}
''');
    await assertHasFix('''
import 'dart:async' as async;

void f(num n) {
  if (n is! async.Future) {}
}
''');
  }

  Future<void> test_swapped() async {
    await resolveTestCode('''
void f(num n) {
  if (String == n) {}
}
''');
    await assertHasFix('''
void f(num n) {
  if (n is String) {}
}
''');
  }

  Future<void> test_typedef() async {
    await resolveTestCode('''
typedef MyInt = int;

void f(num n) {
  if (n != MyInt) {}
}
''');
    await assertHasFix('''
typedef MyInt = int;

void f(num n) {
  if (n is! MyInt) {}
}
''');
  }

  Future<void> test_typeParameter() async {
    await resolveTestCode('''
void f<P>(num n) {
  if (n != P) {}
}
''');
    await assertHasFix('''
void f<P>(num n) {
  if (n is! P) {}
}
''');
  }
}
