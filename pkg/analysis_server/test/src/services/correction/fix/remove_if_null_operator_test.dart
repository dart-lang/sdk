// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeadNullAwareAssignmentExpressionTest);
    defineReflectiveTests(DeadNullAwareExpressionTest);
    defineReflectiveTests(UnnecessaryNullInIfNullOperatorsBulkTest);
    defineReflectiveTests(UnnecessaryNullInIfNullOperatorsTest);
  });
}

bool _ignoreDeadCode(Diagnostic diagnostic) =>
    diagnostic.diagnosticCode != WarningCode.deadCode;

@reflectiveTest
class DeadNullAwareAssignmentExpressionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeIfNullOperator;

  Future<void>
  test_assignmentExpression_propertyAccess_methodInvocation() async {
    await resolveTestCode('''
class C {
  int a = 0;
}

void f() {
  g().a ??= 0;
}

C g() => C();
''');
    await assertHasFix('''
class C {
  int a = 0;
}

void f() {
  g().a;
}

C g() => C();
''', errorFilter: _ignoreDeadCode);
  }

  Future<void> test_assignmentExpression_simpleIdentifier_field() async {
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
  }
}
''', errorFilter: _ignoreDeadCode);
  }

  Future<void> test_assignmentExpression_simpleIdentifier_parameter() async {
    await resolveTestCode('''
void f(int a, int b) {
  a ??= b;
}
''');
    await assertHasFix('''
void f(int a, int b) {
}
''', errorFilter: _ignoreDeadCode);
  }

  Future<void> test_immediateChild() async {
    await resolveTestCode('''
void f(int a, int b) => a ??= b;
''');
    await assertHasFix('''
void f(int a, int b) => a;
''', errorFilter: _ignoreDeadCode);
  }

  Future<void> test_nestedChild() async {
    await resolveTestCode('''
void f(int a, int b) => a ??= b * 2 + 1;
''');
    await assertHasFix('''
void f(int a, int b) => a;
''', errorFilter: _ignoreDeadCode);
  }

  Future<void> test_nestedChild_onRight() async {
    await resolveTestCode('''
void f(int a, int b, int c) => a = b ??= c;
''');
    await assertHasFix('''
void f(int a, int b, int c) => a = b;
''', errorFilter: _ignoreDeadCode);
  }
}

@reflectiveTest
class DeadNullAwareExpressionTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.removeIfNullOperator;

  Future<void> test_immediateChild() async {
    await resolveTestCode('''
int f(int a, int b) => a ?? b;
''');
    await assertHasFix('''
int f(int a, int b) => a;
''', errorFilter: _ignoreDeadCode);
  }

  Future<void> test_nestedChild() async {
    await resolveTestCode('''
int f(int a, int b) => a ?? b * 2 + 1;
''');
    await assertHasFix('''
int f(int a, int b) => a;
''', errorFilter: _ignoreDeadCode);
  }
}

@reflectiveTest
class UnnecessaryNullInIfNullOperatorsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_null_in_if_null_operators;

  @failingTest
  Future<void> test_null_null_left() async {
    // The fix only addresses one null and results in:
    //
    //     var b = null ?? a;
    //
    // (not incorrect but not complete).
    await resolveTestCode('''
var a = '';
var b = null ?? null ?? a;
''');
    await assertHasFix('''
var a = '';
var b = a;
''');
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
var a = '';
var b = null ?? a ?? null;
var c = a ?? null ?? null;
''');
    await assertHasFix('''
var a = '';
var b = a;
var c = a;
''');
  }
}

@reflectiveTest
class UnnecessaryNullInIfNullOperatorsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeIfNullOperator;

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
var b = a ?? '';
''');
    await assertHasFix('''
var a = '';
var b = a;
''', errorFilter: _ignoreDeadCode);
  }
}
