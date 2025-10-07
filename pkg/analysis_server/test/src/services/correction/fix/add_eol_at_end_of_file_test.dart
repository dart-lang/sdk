// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddEolAtEndOfFileTest);
  });
}

@reflectiveTest
class AddEolAtEndOfFileTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addEolAtEndOfFile;

  @override
  String get lintCode => LintNames.eol_at_end_of_file;

  Future<void> test_missing_eol() async {
    await resolveTestCode('''
void f() {
}''');
    await assertHasFix('''
void f() {
}
''');
  }

  Future<void> test_multiple_eol() async {
    await resolveTestCode('''
void f() {
}

''');
    await assertHasFix('''
void f() {
}
''');
  }
}
