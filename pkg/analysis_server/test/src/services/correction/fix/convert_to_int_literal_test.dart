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
    defineReflectiveTests(ConvertToIntLiteralTest);
  });
}

@reflectiveTest
class ConvertToIntLiteralTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_INT_LITERAL;

  @override
  String get lintCode => LintNames.prefer_int_literals;

  /// More coverage in the `convert_to_int_literal_test.dart` assist test.
  Future<void> test_decimal() async {
    await resolveTestCode('''
const double myDouble = 42.0;
''');
    await assertHasFix('''
const double myDouble = 42;
''');
  }
}
