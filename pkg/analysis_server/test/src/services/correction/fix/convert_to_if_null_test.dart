// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfNullTest);
  });
}

@reflectiveTest
class ConvertToIfNullTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_IF_NULL;

  @override
  String get lintCode => LintNames.prefer_if_null_operators;

  Future<void> test_equalEqual() async {
    await resolveTestUnit('''
void f(String s) {
  print(s == null ? 'default' : s);
}
''');
    await assertHasFix('''
void f(String s) {
  print(s ?? 'default');
}
''');
  }

  Future<void> test_notEqual() async {
    await resolveTestUnit('''
void f(String s) {
  print(s != null ? s : 'default');
}
''');
    await assertHasFix('''
void f(String s) {
  print(s ?? 'default');
}
''');
  }
}
