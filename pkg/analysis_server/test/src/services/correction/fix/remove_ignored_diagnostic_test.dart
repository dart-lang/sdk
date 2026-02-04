// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryIgnoreTest);
    defineReflectiveTests(RemoveUnnecessaryIgnoreBulkTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryIgnoreBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_ignore;

  Future<void> test_file() async {
    await resolveTestCode('''
// ignore_for_file: non_bool_negation_expression, return_of_invalid_type
// ignore_for_file: unused_local_variable, return_of_invalid_type

int f() => null;
''');
    await assertHasFix('''
// ignore_for_file: return_of_invalid_type
// ignore_for_file: return_of_invalid_type

int f() => null;
''');
  }

  Future<void> test_line() async {
    await resolveTestCode('''
class C {
  // ignore: non_bool_negation_expression, return_of_invalid_type
  int f() => null;

  // ignore: return_of_invalid_type, unused_local_variable
  int g() => null;
}
''');
    await assertHasFix('''
class C {
  // ignore: return_of_invalid_type
  int f() => null;

  // ignore: return_of_invalid_type
  int g() => null;
}
''');
  }

  Future<void> test_line_multi() async {
    await resolveTestCode('''
class C {
  // ignore: non_bool_negation_expression, return_of_invalid_type
  // ignore: return_of_invalid_type, unused_local_variable
  int g() => null;
}
''');
    await assertHasFix('''
class C {
  // ignore: return_of_invalid_type
  // ignore: return_of_invalid_type
  int g() => null;
}
''');
  }
}

@reflectiveTest
class RemoveUnnecessaryIgnoreTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeIgnoredDiagnostic;

  @override
  String get lintCode => LintNames.unnecessary_ignore;

  Future<void> test_file_first() async {
    await resolveTestCode('''
// ignore_for_file: unused_local_variable, return_of_invalid_type
int f() => null;
''');
    await assertHasFix('''
// ignore_for_file: return_of_invalid_type
int f() => null;
''');
  }

  Future<void> test_file_first_eol() async {
    await resolveTestCode('''
import 'dart:io'; // ignore_for_file: unused_local_variable, unused_import
void f() {}
''');
    await assertHasFix('''
import 'dart:io'; // ignore_for_file: unused_import
void f() {}
''');
  }

  Future<void> test_file_first_leading_and_eol() async {
    await resolveTestCode('''
// ignore_for_file: return_of_invalid_type
import 'dart:io'; // ignore_for_file: unused_local_variable, unused_import
int f() => null;
''');
    await assertHasFix('''
// ignore_for_file: return_of_invalid_type
import 'dart:io'; // ignore_for_file: unused_import
int f() => null;
''');
  }

  Future<void> test_file_last() async {
    await resolveTestCode('''
// ignore_for_file: return_of_invalid_type, unused_local_variable
int f() => null;
''');
    await assertHasFix('''
// ignore_for_file: return_of_invalid_type
int f() => null;
''');
  }

  Future<void> test_file_middle() async {
    await resolveTestCode('''
// ignore_for_file: return_of_invalid_type, unused_local_variable, non_bool_negation_expression
int f() => !null;
''');
    await assertHasFix('''
// ignore_for_file: return_of_invalid_type, non_bool_negation_expression
int f() => !null;
''');
  }

  Future<void> test_line_first() async {
    await resolveTestCode('''
// ignore: unused_local_variable, return_of_invalid_type
int f() => null;
''');
    await assertHasFix('''
// ignore: return_of_invalid_type
int f() => null;
''');
  }

  Future<void> test_line_first_eol() async {
    await resolveTestCode('''
class C {
  int f() => null; // ignore: unused_local_variable, return_of_invalid_type
}''');
    await assertHasFix('''
class C {
  int f() => null; // ignore: return_of_invalid_type
}''');
  }

  Future<void> test_line_first_leading_and_eol() async {
    await resolveTestCode('''
class C {
  // ignore: private_named_non_field_parameter
  int f({required _a}) => null; // ignore: unused_local_variable, return_of_invalid_type
}''');
    await assertHasFix('''
class C {
  // ignore: private_named_non_field_parameter
  int f({required _a}) => null; // ignore: return_of_invalid_type
}''');
  }

  Future<void> test_line_last() async {
    await resolveTestCode('''
// ignore: return_of_invalid_type, unused_local_variable
int f() => null;
''');
    await assertHasFix('''
// ignore: return_of_invalid_type
int f() => null;
''');
  }

  Future<void> test_line_middle() async {
    await resolveTestCode('''
// ignore: return_of_invalid_type, unused_local_variable, non_bool_negation_expression
int f() => !null;
''');
    await assertHasFix('''
// ignore: return_of_invalid_type, non_bool_negation_expression
int f() => !null;
''');
  }
}
