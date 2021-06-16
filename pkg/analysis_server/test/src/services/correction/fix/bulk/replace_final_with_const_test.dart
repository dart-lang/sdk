// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceFinalWithConstTest);
  });
}

@reflectiveTest
class ReplaceFinalWithConstTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_const_declarations;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
final int a = 1;
final b = 1;
''');
    await assertHasFix('''
const int a = 1;
const b = 1;
''');
  }
}
