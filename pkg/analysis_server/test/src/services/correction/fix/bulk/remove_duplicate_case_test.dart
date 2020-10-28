// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDuplicateCaseTest);
  });
}

@reflectiveTest
class RemoveDuplicateCaseTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.no_duplicate_case_values;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void switchInt() {
  switch (2) {
    case 1:
      print('a');
      break;
    case 2:
    case 2:
    case 3:
    case 3:
    default:
      print('?');
  }
}
''');
    await assertHasFix('''
void switchInt() {
  switch (2) {
    case 1:
      print('a');
      break;
    case 2:
    case 3:
    default:
      print('?');
  }
}
''');
  }
}
