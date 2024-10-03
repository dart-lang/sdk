// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNullAwareBulkTest);
    defineReflectiveTests(ConvertToNullAwareTest);
  });
}

@reflectiveTest
class ConvertToNullAwareBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_null_aware_operators;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  int m(int p) => p;
}
int f(A x, A y) => x == null ? null : x.m(y == null ? null : y.m(0));
''');
    await assertHasFix('''
class A {
  int m(int p) => p;
}
int f(A x, A y) => x?.m(y?.m(0));
''');
  }
}

@reflectiveTest
class ConvertToNullAwareTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_NULL_AWARE;

  @override
  String get lintCode => LintNames.prefer_null_aware_operators;

  /// More coverage in the `convert_to_null_aware_test.dart` assist test.
  Future<void> test_equal_nullOnLeft() async {
    await resolveTestCode('''
abstract class A {
  int m();
}
int? f(A? a) => null == a ? null : a.m();
''');
    await assertHasFix('''
abstract class A {
  int m();
}
int? f(A? a) => a?.m();
''');
  }

  Future<void> test_equal_targetAlreadyNullAware() async {
    await resolveTestCode('''
class A {
  late int? value;
}

void f(A bar) {
  final foo = bar.value == null
      ? null
      : bar.value?.sign;
  print(foo);
}
''');
    await assertHasFix('''
class A {
  late int? value;
}

void f(A bar) {
  final foo = bar.value?.sign;
  print(foo);
}
''');
  }

  Future<void> test_equal_targetTrailingNonNullAssert() async {
    await resolveTestCode('''
class A {
  int? x;
}
class C {
  late A foo;
  int? bar;

  void f() {
    bar = foo.x == null
      ? null
      : foo.x!;
  }
}
''');
    await assertHasFix('''
class A {
  int? x;
}
class C {
  late A foo;
  int? bar;

  void f() {
    bar = foo.x;
  }
}
''');
  }

  Future<void> test_notEqual_targetChained() async {
    await resolveTestCode('''
void f(int? bar) {
  final foo = bar != null
      ? bar.sign.remainder(5)
      : null;
  print(foo);
}
''');
    await assertHasFix('''
void f(int? bar) {
  final foo = bar?.sign.remainder(5);
  print(foo);
}
''');
  }

  Future<void> test_notEqual_targetIndexAndNonNullAssert() async {
    await resolveTestCode('''
void f(List a, int i) {
  print(a[i] != null
      ? a[i]!.test()
      : null);
}
''');
    await assertHasFix('''
void f(List a, int i) {
  print(a[i]?.test());
}
''');
  }

  Future<void> test_notEqual_targetNonNullAssertChained() async {
    await resolveTestCode('''
abstract class A {
  int? x;
  int? f() => x != null ? x!.remainder(5) : null;
}
''');
    await assertHasFix('''
abstract class A {
  int? x;
  int? f() => x?.remainder(5);
}
''');
  }

  Future<void> test_notEqual_targetTrailingNonNullAssertSingle() async {
    await resolveTestCode('''
abstract class A {
  String? bar;
  String? f() => bar != null ? bar! : null;
}
''');
    await assertHasFix('''
abstract class A {
  String? bar;
  String? f() => bar;
}
''');
  }
}
