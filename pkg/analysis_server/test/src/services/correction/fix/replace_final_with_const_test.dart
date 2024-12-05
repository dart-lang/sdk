// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceFinalWithConstBulkTest);
    defineReflectiveTests(ReplaceFinalWithConstTest);
  });
}

@reflectiveTest
class ReplaceFinalWithConstBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_declarations;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
final int a = 1;
final b = 1;
''');
    await assertHasFix('''
const int a = 1;
const b = 1;
''');
  }
}

@reflectiveTest
class ReplaceFinalWithConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_FINAL_WITH_CONST;

  @override
  String get lintCode => LintNames.prefer_const_declarations;

  Future<void> test_const_instanceCreation() async {
    await resolveTestCode('''
class A {
  const A();
}
final a = const A();
''');
    await assertHasFix('''
class A {
  const A();
}
const a = A();
''');
  }

  Future<void> test_const_instanceCreation_multiple() async {
    await resolveTestCode('''
class A {
  const A();
}
final A a1 = const A(), a2 = const A();
''');
    await assertHasFix('''
class A {
  const A();
}
const A a1 = A(), a2 = A();
''');
  }

  Future<void> test_const_typedLiteral() async {
    await resolveTestCode('''
final b = const [];
''');
    await assertHasFix('''
const b = [];
''');
  }

  Future<void> test_emptyRecordLiteral() async {
    await resolveTestCode('''
final () a = ();
''');
    await assertHasFix('''
const () a = ();
''');
  }

  Future<void> test_recordLiteral() async {
    await resolveTestCode('''
final (int, int) a = (1, 2);
''');
    await assertHasFix('''
const (int, int) a = (1, 2);
''');
  }

  Future<void> test_recordLiteral_nonConst() async {
    await resolveTestCode('''
void f(int a) {
  final (int, int) r = (a, a);
}
''');
    await assertNoFix();
  }

  Future<void> test_variable() async {
    await resolveTestCode('''
final int a = 1;
''');
    await assertHasFix('''
const int a = 1;
''');
  }
}
