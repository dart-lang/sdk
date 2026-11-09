// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceWithIsEvenBulkTest);
    defineReflectiveTests(ReplaceWithIsEvenTest);
    defineReflectiveTests(ReplaceWithIsOddTest);
  });
}

@reflectiveTest
class ReplaceWithIsEvenBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_is_even_rather_than_modulo;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(int i, int j) {
  if (i % 2 == 0) {}
  if (j % 2 == 1) {}
}
''');
    await assertHasFix('''
void f(int i, int j) {
  if (i.isEven) {}
  if (j.isOdd) {}
}
''');
  }
}

@reflectiveTest
class ReplaceWithIsEvenTest extends FixProcessorForBuiltInLintRuleTest {
  @override
  FixKind get kind => DartFixKind.replaceWithIsEven;

  @override
  String get lintCode => LintNames.use_is_even_rather_than_modulo;

  Future<void> test_additive() async {
    await resolveTestCode('''
void f(int a, int b) {
  if ((a + b) % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int a, int b) {
  if ((a + b).isEven) {}
}
''');
  }

  Future<void> test_await() async {
    await resolveTestCode('''
Future<void> f(Future<int> value) async {
  if (await value % 2 == 0) {}
}
''');
    await assertHasFix('''
Future<void> f(Future<int> value) async {
  if ((await value).isEven) {}
}
''');
  }

  Future<void> test_call() async {
    await resolveTestCode('''
int f() => 0;

void g() {
  if (f() % 2 == 0) {}
}
''');
    await assertHasFix('''
int f() => 0;

void g() {
  if (f().isEven) {}
}
''');
  }

  Future<void> test_commentBeforeOperator() async {
    await resolveTestCode('''
void f(int i) {
  if (i /* keep */ % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int i) {
  if (i /* keep */.isEven) {}
}
''');
  }

  Future<void> test_identifier() async {
    await resolveTestCode('''
void f(int i) {
  if (i % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int i) {
  if (i.isEven) {}
}
''');
  }

  Future<void> test_literal() async {
    await resolveTestCode('''
var a = 1 % 2 == 0;
''');
    await assertHasFix('''
var a = 1.isEven;
''');
  }

  Future<void> test_multiplicative_needsParentheses() async {
    await resolveTestCode('''
void f(int a, int b) {
  if (a * b % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int a, int b) {
  if ((a * b).isEven) {}
}
''');
  }

  Future<void> test_nullAssert() async {
    await resolveTestCode('''
void f(int? i) {
  if (i! % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int? i) {
  if (i!.isEven) {}
}
''');
  }

  Future<void> test_postfixIncrement_needsParentheses() async {
    await resolveTestCode('''
void f(int i) {
  if (i++ % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int i) {
  if ((i++).isEven) {}
}
''');
  }

  Future<void> test_prefixMinus() async {
    await resolveTestCode('''
void f(int a) {
  if (-a % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int a) {
  if ((-a).isEven) {}
}
''');
  }

  Future<void> test_propertyAccess() async {
    await resolveTestCode('''
void f(int i) {
  if (i.sign % 2 == 0) {}
}
''');
    await assertHasFix('''
void f(int i) {
  if (i.sign.isEven) {}
}
''');
  }
}

@reflectiveTest
class ReplaceWithIsOddTest extends FixProcessorForBuiltInLintRuleTest {
  @override
  FixKind get kind => DartFixKind.replaceWithIsOdd;

  @override
  String get lintCode => LintNames.use_is_even_rather_than_modulo;

  Future<void> test_identifier() async {
    await resolveTestCode('''
void f(int i) {
  if (i % 2 == 1) {}
}
''');
    await assertHasFix('''
void f(int i) {
  if (i.isOdd) {}
}
''');
  }

  Future<void> test_prefixMinus() async {
    await resolveTestCode('''
void f(int a) {
  if (-a % 2 == 1) {}
}
''');
    await assertHasFix('''
void f(int a) {
  if ((-a).isOdd) {}
}
''');
  }
}
