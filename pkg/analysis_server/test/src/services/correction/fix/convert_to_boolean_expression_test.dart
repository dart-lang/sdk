// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToBoolExpressionBulkTest);
    defineReflectiveTests(ConvertToBoolExpressionTest);
  });
}

@reflectiveTest
class ConvertToBoolExpressionBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.no_literal_bool_comparisons;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(bool value) {
  if (value != false || value == false) print(value);
}
''');
    await assertHasFix('''
void f(bool value) {
  if (value || !value) print(value);
}
''');
  }
}

@reflectiveTest
class ConvertToBoolExpressionTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_BOOL_EXPRESSION;

  @override
  String get lintCode => LintNames.no_literal_bool_comparisons;

  Future<void> test_ifFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (value == false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (!value) print(value);
}
''');
  }

  Future<void> test_ifFalse_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (false == value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (!value) print(value);
}
''');
  }

  Future<void> test_ifNotFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (value != false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (value) print(value);
}
''');
  }

  Future<void> test_ifNotFalse_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (false != value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (value) print(value);
}
''');
  }

  Future<void> test_ifNotTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (value != true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (!value) print(value);
}
''');
  }

  Future<void> test_ifNotTrue_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (true != value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (!value) print(value);
}
''');
  }

  Future<void> test_ifTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (value == true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (value) print(value);
}
''');
  }

  Future<void> test_ifTrue_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
 if (true == value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
 if (value) print(value);
}
''');
  }
}
