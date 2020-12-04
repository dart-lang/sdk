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
    defineReflectiveTests(ReplaceWithBracketsTest);
  });
}

@reflectiveTest
class ReplaceWithBracketsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_BRACKETS;

  @override
  String get lintCode => LintNames.empty_statements;

  Future<void> test_outOfBlock_otherLine() async {
    await resolveTestCode('''
void f(bool c) {
  while(c)
  ;
  print('hi');
}
''');
    await assertHasFix('''
void f(bool c) {
  while(c) {}
  print('hi');
}
''');
  }

  Future<void> test_outOfBlock_sameLine() async {
    await resolveTestCode('''
void f(bool c) {
  while(c);
  print('hi');
}
''');
    await assertHasFix('''
void f(bool c) {
  while(c) {}
  print('hi');
}
''');
  }
}
