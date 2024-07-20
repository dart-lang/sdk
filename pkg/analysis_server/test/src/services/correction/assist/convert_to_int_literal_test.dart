// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIntLiteralTest);
  });
}

@reflectiveTest
class ConvertToIntLiteralTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_INT_LITERAL;

  Future<void> test_decimal() async {
    await resolveTestCode('''
const double myDouble = /*caret*/42.0;
''');
    await assertHasAssist('''
const double myDouble = 42;
''');
  }

  Future<void> test_decimal_negative() async {
    await resolveTestCode('''
const double myDouble = -/*caret*/42.0;
''');
    await assertHasAssist('''
const double myDouble = -42;
''');
  }

  Future<void> test_decimal_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_int_literals]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
const double myDouble = /*caret*/42.0;
''');
    await assertNoAssist();
  }

  Future<void> test_decimal_noDigitsLeftOfDecimal() async {
    await resolveTestCode('''
const double myDouble = /*caret*/.0;
''');
    await assertHasAssist('''
const double myDouble = 0;
''');
  }

  Future<void> test_decimalWithSeparators() async {
    await resolveTestCode('''
const double myDouble = /*caret*/4_200.000_000;
''');
    await assertHasAssist('''
const double myDouble = 4_200;
''');
  }

  Future<void> test_notDouble() async {
    await resolveTestCode('''
const double myDouble = /*caret*/42;
''');
    await assertNoAssist();
  }

  Future<void> test_scientific() async {
    await resolveTestCode('''
const double myDouble = /*caret*/4.2e3;
''');
    await assertHasAssist('''
const double myDouble = 4200;
''');
  }

  Future<void> test_scientificWithCapitalE() async {
    await resolveTestCode('''
const double myDouble = /*caret*/4.2E3;
''');
    await assertHasAssist('''
const double myDouble = 4200;
''');
  }

  Future<void> test_scientificWithSeparators() async {
    await resolveTestCode('''
const double myDouble = /*caret*/4_00.200_000e3;
''');
    await assertHasAssist('''
const double myDouble = 400200;
''');
  }

  Future<void> test_tooBig() async {
    await resolveTestCode('''
const double myDouble = /*caret*/4.2e99999;
''');
    await assertNoAssist();
  }
}
