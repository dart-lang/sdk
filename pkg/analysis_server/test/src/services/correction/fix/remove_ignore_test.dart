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
  });
}

// TODO(pq): add bulk fix tests
@reflectiveTest
class RemoveUnnecessaryIgnoreTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_IGNORED_DIAGNOSTIC;

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
