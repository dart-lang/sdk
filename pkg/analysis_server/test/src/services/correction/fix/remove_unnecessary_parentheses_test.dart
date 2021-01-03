// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryParenthesesTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryParenthesesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_UNNECESSARY_PARENTHESES;

  @override
  String get lintCode => LintNames.unnecessary_parenthesis;

  Future<void> test_all() async {
    await resolveTestCode('''
void f() {
  (1);
  (22);
  (333);
}
''');
    var lintCode = await lintCodeByName(this.lintCode);
    await assertHasFixAllFix(lintCode, '''
void f() {
  1;
  22;
  333;
}
''');
  }

  Future<void> test_double_atInner() async {
    await resolveTestCode('''
void f() {
  ((42));
}
''');
    await assertNoFix(errorFilter: (e) => e.offset == 14);
  }

  Future<void> test_double_atOuter() async {
    await resolveTestCode('''
void f() {
  ((42));
}
''');
    await assertHasFix('''
void f() {
  (42);
}
''', errorFilter: (e) => e.offset == 13);
  }

  Future<void> test_single() async {
    await resolveTestCode('''
void f() {
  (42);
}
''');
    await assertHasFix('''
void f() {
  42;
}
''');
  }
}
