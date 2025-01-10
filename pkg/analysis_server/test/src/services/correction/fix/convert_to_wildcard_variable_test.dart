// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToWildcardVariableTest);
    defineReflectiveTests(ConvertUnnecessaryUnderscoresTest);
  });
}

@reflectiveTest
class ConvertToWildcardVariableTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_WILDCARD_VARIABLE;

  Future<void> test_convertUnusedLocalVariable() async {
    await resolveTestCode('''
void f() {
  var x = '';
}
''');
    await assertHasFix('''
void f() {
  var _ = '';
}
''');
  }

  Future<void> test_convertUnusedLocalVariable_list() async {
    await resolveTestCode('''
void f() {
  int? x, y;
  y;
}
''');
    await assertHasFix('''
void f() {
  int? _, y;
  y;
}
''');
  }

  Future<void> test_convertUnusedLocalVariable_listPatternAssignment() async {
    await resolveTestCode('''
void f() {
  var x = 0;
  [x, _] = [1, 2];
}
''');
    await assertHasFix('''
void f() {
  var _ = 0;
  [_, _] = [1, 2];
}
''');
  }

  Future<void> test_convertUnusedLocalVariable_preWildcards() async {
    await resolveTestCode('''
// @dart = 3.4
// (pre wildcard-variables)

void f() {
  var x = '';
}
''');
    await assertNoFix();
  }

  Future<void> test_convertUnusedLocalVariable_recordAssignment() async {
    await resolveTestCode('''
void f() {
  var x = 0;
  (x, _) = (1, 2);
}
''');
    await assertHasFix('''
void f() {
  var _ = 0;
  (_, _) = (1, 2);
}
''');
  }

  Future<void>
  test_convertUnusedLocalVariable_recordAssignment_parenthesized() async {
    await resolveTestCode('''
void f() {
  var x = 0;
  ((x, _)) = (1, 2);
}
''');
    await assertHasFix('''
void f() {
  var _ = 0;
  ((_, _)) = (1, 2);
}
''');
  }

  Future<void> test_convertUnusedLocalVariable_reference() async {
    await resolveTestCode('''
void f() {
  var x = '';
  x = '';
}
''');
    // Converting the simple identifier `x` would result in invalid code.
    await assertNoFix();
  }
}

@reflectiveTest
class ConvertUnnecessaryUnderscoresTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_WILDCARD_VARIABLE;

  @override
  String get lintCode => LintNames.unnecessary_underscores;

  Future<void> test_functionParameter() async {
    await resolveTestCode(r'''
void f(int __) {}
''');
    await assertHasFix(r'''
void f(int _) {}
''');
  }

  Future<void> test_localVariable() async {
    await resolveTestCode(r'''
void f() {
  // ignore: UNUSED_LOCAL_VARIABLE
  int __ = 0;
}
''');
    await assertHasFix(r'''
void f() {
  // ignore: UNUSED_LOCAL_VARIABLE
  int _ = 0;
}
''');
  }
}
