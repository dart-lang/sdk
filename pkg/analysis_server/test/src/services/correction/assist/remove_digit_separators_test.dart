// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveDigitSeparatorsTest);
  });
}

@reflectiveTest
class RemoveDigitSeparatorsTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REMOVE_DIGIT_SEPARATORS;

  Future<void> test_double_noSeparators() async {
    await resolveTestCode('var i = /*caret*/123456.78;');
    await assertNoAssist();
  }

  Future<void> test_double_separators() async {
    await resolveTestCode('var i = /*caret*/111_222.333_444;');
    await assertHasAssist('var i = 111222.333444;');
  }

  Future<void> test_doubleScientific_fractional_separators() async {
    await resolveTestCode('var i = /*caret*/1_2.3_4e5_6;');
    await assertHasAssist('var i = 12.34e56;');
  }

  Future<void> test_doubleScientific_negative_separators() async {
    await resolveTestCode('var i = /*caret*/12_34e-56_78;');
    await assertHasAssist('var i = 1234e-5678;');
  }

  Future<void> test_doubleScientific_noSeparators() async {
    await resolveTestCode('var i = /*caret*/123e456;');
    await assertNoAssist();
  }

  Future<void> test_doubleScientific_separators() async {
    await resolveTestCode('var i = /*caret*/12_34e56_78;');
    await assertHasAssist('var i = 1234e5678;');
  }

  Future<void> test_intDecimal_negative_separators() async {
    await resolveTestCode('var i = -/*caret*/12___34__56_78;');
    await assertHasAssist('var i = -12345678;');
  }

  Future<void> test_intDecimal_noSeparators() async {
    await resolveTestCode('var i = /*caret*/123456;');
    await assertNoAssist();
  }

  Future<void> test_intDecimal_separators() async {
    await resolveTestCode('var i = /*caret*/123__456_78;');
    await assertHasAssist('var i = 12345678;');
  }

  Future<void> test_intHex_noSeparators() async {
    await resolveTestCode('var i = /*caret*/0x123456;');
    await assertNoAssist();
  }

  Future<void> test_intHex_separators() async {
    await resolveTestCode('var i = /*caret*/0x1___234__5_6;');
    await assertHasAssist('var i = 0x123456;');
  }

  Future<void> test_intHex_upperCase_separators() async {
    await resolveTestCode('var i = /*caret*/0X12_34_56;');
    await assertHasAssist('var i = 0X123456;');
  }
}
