// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseEffectiveIntegerDivisionTest);
    defineReflectiveTests(UseEffectiveIntegerDivisionMultiTest);
  });
}

@reflectiveTest
class UseEffectiveIntegerDivisionMultiTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_truncating_division;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  var a = 5;
  var b = 2;
  print((a / (a / b).toInt()).toInt());
}
''');
    await assertHasFix('''
void f() {
  var a = 5;
  var b = 2;
  print(a ~/ (a ~/ b));
}
''');
  }

  Future<void> test_singleFile_extraParentheses() async {
    await resolveTestCode('''
void f() {
  var a = 5;
  var b = 2;
  print((a / ((a / b).toInt())).toInt());
}
''');
    await assertHasFix('''
void f() {
  var a = 5;
  var b = 2;
  print(a ~/ ((a ~/ b)));
}
''');
  }
}

@reflectiveTest
class UseEffectiveIntegerDivisionTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.USE_EFFECTIVE_INTEGER_DIVISION;

  @override
  String get lintCode => LintNames.use_truncating_division;

  Future<void> test_normalDivision() async {
    await resolveTestCode('''
void f() {
  var a = 5;
  var b = 2;
  print((a / b).toInt());
}
''');
    await assertHasFix('''
void f() {
  var a = 5;
  var b = 2;
  print(a ~/ b);
}
''');
  }

  Future<void> test_normalDivision_targetOfCascadedPropertyAccess() async {
    await resolveTestCode('''
void f() {
  (1 / 2).toInt()..isEven;
}
''');
    // This is surprising, but... `1 ~/ 2..isEven` is parsed the same as
    // `(1 ~/ 2)..isEven`.
    await assertHasFix('''
void f() {
  1 ~/ 2..isEven;
}
''');
  }

  Future<void> test_normalDivision_targetOfMethodCall() async {
    await resolveTestCode('''
void f() {
  (1 / 2).toInt().toString();
}
''');
    await assertHasFix('''
void f() {
  (1 ~/ 2).toString();
}
''');
  }
}
