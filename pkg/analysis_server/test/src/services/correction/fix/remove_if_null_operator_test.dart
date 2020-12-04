// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../abstract_context.dart';
import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadNullAwareAssignmentExpressionTest);
    defineReflectiveTests(DeadNullAwareExpressionTest);
    defineReflectiveTests(UnnecessaryNullInIfNullOperatorsTest);
  });
}

@reflectiveTest
class DeadNullAwareAssignmentExpressionTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.REMOVE_IF_NULL_OPERATOR;

  Future<void> test_assignmentExpression_nonPromotable() async {
    await resolveTestCode('''
class C {
  int a = 1;
  void f(int b) {
    a ??= b;
  }
}
''');
    await assertHasFix('''
class C {
  int a = 1;
  void f(int b) {
    a;
  }
}
''');
  }

  Future<void> test_assignmentExpression_promotable() async {
    await resolveTestCode('''
void f(int a, int b) {
  a ??= b;
}
''');
    await assertHasFix('''
void f(int a, int b) {
}
''');
  }

  Future<void> test_immediateChild() async {
    await resolveTestCode('''
void f(int a, int b) => a ??= b;
''');
    await assertHasFix('''
void f(int a, int b) => a;
''');
  }

  Future<void> test_nestedChild() async {
    await resolveTestCode('''
void f(int a, int b) => a ??= b * 2 + 1;
''');
    await assertHasFix('''
void f(int a, int b) => a;
''');
  }

  Future<void> test_nestedChild_onRight() async {
    await resolveTestCode('''
void f(int a, int b, int c) => a = b ??= c;
''');
    await assertHasFix('''
void f(int a, int b, int c) => a = b;
''');
  }
}

@reflectiveTest
class DeadNullAwareExpressionTest extends FixProcessorTest
    with WithNullSafetyMixin {
  @override
  FixKind get kind => DartFixKind.REMOVE_IF_NULL_OPERATOR;

  Future<void> test_immediateChild() async {
    await resolveTestCode('''
int f(int a, int b) => a ?? b;
''');
    await assertHasFix('''
int f(int a, int b) => a;
''');
  }

  Future<void> test_nestedChild() async {
    await resolveTestCode('''
int f(int a, int b) => a ?? b * 2 + 1;
''');
    await assertHasFix('''
int f(int a, int b) => a;
''');
  }
}

@reflectiveTest
class UnnecessaryNullInIfNullOperatorsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_IF_NULL_OPERATOR;

  @override
  String get lintCode => LintNames.unnecessary_null_in_if_null_operators;

  Future<void> test_left() async {
    await resolveTestCode('''
var a = '';
var b = null ?? a;
''');
    await assertHasFix('''
var a = '';
var b = a;
''');
  }

  Future<void> test_right() async {
    await resolveTestCode('''
var a = '';
var b = a ?? null;
''');
    await assertHasFix('''
var a = '';
var b = a;
''');
  }
}
