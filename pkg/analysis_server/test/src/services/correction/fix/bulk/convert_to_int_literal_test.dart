// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIntLiteralTest);
  });
}

@reflectiveTest
class ConvertToIntLiteralTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_int_literals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
const double d1 = 42.0;
double d2 = 7.0e2;
''');
    await assertHasFix('''
const double d1 = 42;
double d2 = 700;
''');
  }
}
