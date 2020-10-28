// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToContainsTest);
  });
}

@reflectiveTest
class ConvertToContainsTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_CONTAINS;

  @override
  String get lintCode => LintNames.prefer_contains;

  Future<void> test_left_bangEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 != list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}
''');
  }

  Future<void> test_left_eqEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 == list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }

  Future<void> test_left_gt_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 > list.indexOf(value);
}
''');
    await assertNoFix();
  }

  Future<void> test_left_gt_zero() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return 0 > list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }

  Future<void> test_left_gtEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 >= list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }

  Future<void> test_left_lt_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 < list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}
''');
  }

  Future<void> test_left_ltEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 <= list.indexOf(value);
}
''');
    await assertNoFix();
  }

  Future<void> test_left_ltEq_zero() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return 0 <= list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}
''');
  }

  Future<void> test_right_bangEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) != -1;
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}
''');
  }

  Future<void> test_right_eqEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) == -1;
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }

  Future<void> test_right_gt_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) > -1;
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}
''');
  }

  Future<void> test_right_gtEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) >= -1;
}
''');
    await assertNoFix();
  }

  Future<void> test_right_gtEq_zero() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) >= 0;
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}
''');
  }

  Future<void> test_right_lt_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) < -1;
}
''');
    await assertNoFix();
  }

  Future<void> test_right_lt_zero() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) < 0;
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }

  Future<void> test_right_ltEq_minusOne() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return list.indexOf(value) <= -1;
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }
}
