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
    defineReflectiveTests(RemoveEmptyCatchTest);
  });
}

@reflectiveTest
class RemoveEmptyCatchTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EMPTY_CATCH;

  @override
  String get lintCode => LintNames.empty_catches;

  Future<void> test_incompleteCatch() async {
    await resolveTestCode('''
void foo() {
  try {
    1;
  } catch 2;
}
''');
    assertNoExceptions();
  }

  Future<void> test_singleCatch_finally_newLine() async {
    await resolveTestCode('''
void foo() {
  try {
    1;
  } catch (e) {
  } finally {
    2;
  }
}
''');
    await assertHasFix('''
void foo() {
  try {
    1;
  } finally {
    2;
  }
}
''');
  }

  Future<void> test_singleCatch_finally_sameLine() async {
    await resolveTestCode('''
void foo() {
  try {} catch (e) {} finally {}
}
''');
    await assertHasFix('''
void foo() {
  try {} finally {}
}
''');
  }

  Future<void> test_singleCatch_noFinally() async {
    // The catch can't be removed unless we also remove the try, which is more
    // than this fix does at the moment.
    await resolveTestCode('''
void foo() {
  try {
  } catch (e) {}
}
''');
    await assertNoFix();
  }
}
