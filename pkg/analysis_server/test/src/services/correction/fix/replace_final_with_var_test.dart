// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceFinalWithVarBulkTest);
    defineReflectiveTests(ReplaceFinalWithVarTest);
  });
}

@reflectiveTest
class ReplaceFinalWithVarBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_final;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f() {
  final int a = 1;
  final b = 1;
  final c = 1;
  print(a + b + c);
}
''');
    await assertHasFix('''
void f() {
  final int a = 1;
  var b = 1;
  var c = 1;
  print(a + b + c);
}
''');
  }
}

@reflectiveTest
class ReplaceFinalWithVarTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_FINAL_WITH_VAR;

  @override
  String get lintCode => LintNames.unnecessary_final;

  Future<void> test_method() async {
    await resolveTestCode('''
void f() {
  final a = 1;
  print(a);
}
''');
    await assertHasFix('''
void f() {
  var a = 1;
  print(a);
}
''');
  }
}
