// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryNullInIfNullOperatorsTest);
  });
}

@reflectiveTest
class UnnecessaryNullInIfNullOperatorsTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_null_in_if_null_operators;

  @failingTest
  Future<void> test_null_null_left() async {
    // The fix only addresses one null and results in:
    //
    //     var b = null ?? a;
    //
    // (not incorrect but not complete).
    await resolveTestCode('''
var a = '';
var b = null ?? null ?? a;
''');
    await assertHasFix('''
var a = '';
var b = a;
''');
  }

  Future<void> test_singleFile() async {
    await resolveTestCode('''
var a = '';
var b = null ?? a ?? null;
var c = a ?? null ?? null;
''');
    await assertHasFix('''
var a = '';
var b = a;
var c = a;
''');
  }
}
