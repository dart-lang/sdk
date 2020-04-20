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
    defineReflectiveTests(ReplaceFinalWithConstTest);
  });
}

@reflectiveTest
class ReplaceFinalWithConstTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_FINAL_WITH_CONST;

  @override
  String get lintCode => LintNames.prefer_const_declarations;

  Future<void> test_method() async {
    await resolveTestUnit('''
final int a = 1;
''');
    await assertHasFix('''
const int a = 1;
''');
  }
}
