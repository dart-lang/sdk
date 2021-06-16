// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToContainsTest);
  });
}

@reflectiveTest
class ConvertToContainsTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_contains;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
bool f(List<int> list, int value) {
  return -1 != list.indexOf(value);
}

bool f2(List<int> list, int value) {
  return 0 > list.indexOf(value);
}
''');
    await assertHasFix('''
bool f(List<int> list, int value) {
  return list.contains(value);
}

bool f2(List<int> list, int value) {
  return !list.contains(value);
}
''');
  }
}
