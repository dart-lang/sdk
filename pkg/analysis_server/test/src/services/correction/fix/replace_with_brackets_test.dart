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
    defineReflectiveTests(ReplaceWithBracketsTest);
  });
}

@reflectiveTest
class ReplaceWithBracketsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_BRACKETS;

  @override
  String get lintCode => LintNames.empty_statements;

  test_outOfBlock_otherLine() async {
    await resolveTestUnit('''
void foo() {
  while(true)
  /*LINT*/;
  print('hi');
}
''');
    await assertHasFix('''
void foo() {
  while(true) {}
  print('hi');
}
''');
  }

  test_outOfBlock_sameLine() async {
    await resolveTestUnit('''
void foo() {
  while(true)/*LINT*/;
  print('hi');
}
''');
    await assertHasFix('''
void foo() {
  while(true) {}
  print('hi');
}
''');
  }
}
