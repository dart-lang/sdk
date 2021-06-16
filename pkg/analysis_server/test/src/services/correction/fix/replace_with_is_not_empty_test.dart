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
    defineReflectiveTests(ReplaceWithIsNotEmptyTest);
  });
}

@reflectiveTest
class ReplaceWithIsNotEmptyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REPLACE_WITH_IS_NOT_EMPTY;

  @override
  String get lintCode => LintNames.prefer_is_empty;

  Future<void> test_constantOnLeft_lessThanOrEqual() async {
    await resolveTestCode('''
f(List c) {
  if (1 <= c.length) {}
}
''');
    await assertHasFix('''
f(List c) {
  if (c.isNotEmpty) {}
}
''');
  }

  Future<void> test_constantOnLeft_notEqual() async {
    await resolveTestCode('''
f(List c) {
  if (0 != c.length) {}
}
''');
    await assertHasFix('''
f(List c) {
  if (c.isNotEmpty) {}
}
''');
  }

  Future<void> test_constantOnRight_greaterThanOrEqual() async {
    await resolveTestCode('''
f(List c) {
  if (c.length >= 1) {}
}
''');
    await assertHasFix('''
f(List c) {
  if (c.isNotEmpty) {}
}
''');
  }

  Future<void> test_constantOnRight_notEqual() async {
    await resolveTestCode('''
f(List c) {
  if (c.length != 0) {}
}
''');
    await assertHasFix('''
f(List c) {
  if (c.isNotEmpty) {}
}
''');
  }
}
