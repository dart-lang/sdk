// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseIsNotEmptyBulkTest);
    defineReflectiveTests(UseIsNotEmptyTest);
  });
}

@reflectiveTest
class UseIsNotEmptyBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_is_not_empty;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(List<int> l) {
  if (!l.isEmpty) {}
  if (!l.isEmpty || true) {}
}
''');
    await assertHasFix('''
void f(List<int> l) {
  if (l.isNotEmpty) {}
  if (l.isNotEmpty || true) {}
}
''');
  }
}

@reflectiveTest
class UseIsNotEmptyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.USE_IS_NOT_EMPTY;

  @override
  String get lintCode => LintNames.prefer_is_not_empty;

  Future<void> test_notIsEmpty() async {
    await resolveTestCode('''
f(List<int> l) {
  if (!l.isEmpty) {}
}
''');
    await assertHasFix('''
f(List<int> l) {
  if (l.isNotEmpty) {}
}
''');
  }
}
