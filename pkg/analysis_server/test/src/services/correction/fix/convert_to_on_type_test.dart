// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToOnTypeTest);
  });
}

@reflectiveTest
class ConvertToOnTypeTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_ON_TYPE;

  @override
  String get lintCode => LintNames.avoid_types_as_parameter_names;

  Future<void> test_withOnType() async {
    await resolveTestCode('''
void f() {
  try {
  } on ArgumentError catch (Object) {
  }
}
''');
    await assertNoFix(
      errorFilter: lintNameFilter(
        LintNames.avoid_types_as_parameter_names,
      ),
    );
  }

  Future<void> test_withoutStackTrace() async {
    await resolveTestCode('''
void f() {
  try {
  } catch (ArgumentError) {
  }
}
''');
    await assertHasFix('''
void f() {
  try {
  } on ArgumentError {
  }
}
''');
  }

  Future<void> test_withStackTrace() async {
    await resolveTestCode('''
void f() {
  try {
  } catch (ArgumentError, st) {
    st;
  }
}
''');
    await assertHasFix('''
void f() {
  try {
  } on ArgumentError catch (_, st) {
    st;
  }
}
''');
  }
}
