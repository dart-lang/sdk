// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveBreakBulkTest);
    defineReflectiveTests(RemoveBreakTest);
  });
}

@reflectiveTest
class RemoveBreakBulkTest extends BulkFixProcessorTest {
  @override
  List<String> get experiments => ['patterns', 'records'];

  @override
  String get lintCode => LintNames.unnecessary_breaks;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f() {
  switch (1) {
    case 1:
      f();
      break;
    case 2:
      f();
      break;
  }
}
''');
    await assertHasFix('''
f() {
  switch (1) {
    case 1:
      f();
    case 2:
      f();
  }
}
''');
  }
}

@reflectiveTest
class RemoveBreakTest extends FixProcessorLintTest {
  @override
  List<String> get experiments => ['patterns', 'records'];

  @override
  FixKind get kind => DartFixKind.REMOVE_BREAK;

  @override
  String get lintCode => LintNames.unnecessary_breaks;

  Future<void> test_single() async {
    await resolveTestCode('''
f() {
  switch (1) {
    case 1:
      f();
      break;
    case 2:
      f();
  }
}
''');
    await assertHasFix('''
f() {
  switch (1) {
    case 1:
      f();
    case 2:
      f();
  }
}
''');
  }
}
