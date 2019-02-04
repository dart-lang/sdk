// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveEmptyElseTest);
  });
}

@reflectiveTest
class RemoveEmptyElseTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_EMPTY_ELSE;

  @override
  String get lintCode => LintNames.avoid_empty_else;

  test_newLine() async {
    await resolveTestUnit('''
void foo(bool cond) {
  if (cond) {
    //
  }
  else /*LINT*/;
}
''');
    await assertHasFix('''
void foo(bool cond) {
  if (cond) {
    //
  }
}
''');
  }

  test_sameLine() async {
    await resolveTestUnit('''
void foo(bool cond) {
  if (cond) {
    //
  } else /*LINT*/;
}
''');
    await assertHasFix('''
void foo(bool cond) {
  if (cond) {
    //
  }
}
''');
  }
}
