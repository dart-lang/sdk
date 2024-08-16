// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddDigitSeparatorsTest);
  });
}

@reflectiveTest
class AddDigitSeparatorsTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ADD_DIGIT_SEPARATORS;

  Future<void> test_double_manyDigitsLeftOfDecimal() async {
    await resolveTestCode('var i = /*caret*/123456.78;');
    await assertHasAssist('var i = 123_456.78;');
  }

  Future<void> test_double_multipleOfThreeDigits_rightOfDecimal() async {
    await resolveTestCode('var i = /*caret*/1.234567;');
    await assertHasAssist('var i = 1.234_567;');
  }

  Future<void> test_double_multipleOfThreeDigitsPlusOne_rightOfDecimal() async {
    await resolveTestCode('var i = /*caret*/1.2345678;');
    await assertHasAssist('var i = 1.234_567_8;');
  }

  Future<void> test_double_multipleOfThreeDigitsPlusTwo_rightOfDecimal() async {
    await resolveTestCode('var i = /*caret*/1.23456789;');
    await assertHasAssist('var i = 1.234_567_89;');
  }

  Future<void> test_double_tooFewDigits() async {
    await resolveTestCode('var i = /*caret*/1234.5678;');
    await assertNoAssist();
  }

  Future<void> test_doubleScientific_manyDigitsInExponential() async {
    await resolveTestCode('var i = /*caret*/1e23456;');
    await assertHasAssist('var i = 1e23_456;');
  }

  Future<void> test_doubleScientific_manyDigitsInExponential_negative() async {
    await resolveTestCode('var i = /*caret*/1e-234567;');
    await assertHasAssist('var i = 1e-234_567;');
  }

  Future<void>
      test_doubleScientific_manyDigitsInExponential_withFractional() async {
    await resolveTestCode('var i = /*caret*/1.2e34567;');
    await assertHasAssist('var i = 1.2e34_567;');
  }

  Future<void> test_doubleScientific_manyDigitsInFractional() async {
    await resolveTestCode('var i = /*caret*/1.23456e7;');
    await assertHasAssist('var i = 1.234_56e7;');
  }

  Future<void> test_doubleScientific_manyDigitsInWhole() async {
    await resolveTestCode('var i = /*caret*/12345e6;');
    await assertHasAssist('var i = 12_345e6;');
  }

  Future<void> test_doubleScientific_manyDigitsInWhole_negative() async {
    await resolveTestCode('var i = /*caret*/12345e-6;');
    await assertHasAssist('var i = 12_345e-6;');
  }

  Future<void> test_doubleScientific_manyDigitsInWhole_withFractional() async {
    await resolveTestCode('var i = /*caret*/12345.6e7;');
    await assertHasAssist('var i = 12_345.6e7;');
  }

  Future<void> test_intDecimal_existingSeparators() async {
    await resolveTestCode('var i = /*caret*/123__456_78;');
    await assertHasAssist('var i = 12_345_678;');
  }

  Future<void> test_intDecimal_existingSeparators_correct() async {
    await resolveTestCode('var i = /*caret*/12_345_678;');
    await assertNoAssist();
  }

  Future<void> test_intDecimal_fourDigits() async {
    await resolveTestCode('var i = /*caret*/1234;');
    await assertNoAssist();
  }

  Future<void> test_intDecimal_multipleOfThreeDigits() async {
    await resolveTestCode('var i = /*caret*/123456;');
    await assertHasAssist('var i = 123_456;');
  }

  Future<void> test_intDecimal_multipleOfThreeDigitsPlusOne() async {
    await resolveTestCode('var i = /*caret*/1234567;');
    await assertHasAssist('var i = 1_234_567;');
  }

  Future<void> test_intDecimal_multipleOfThreeDigitsPlusTwo() async {
    await resolveTestCode('var i = /*caret*/12345678;');
    await assertHasAssist('var i = 12_345_678;');
  }

  Future<void> test_intDecimal_negativeNumber() async {
    await resolveTestCode('var i = -/*caret*/12345678;');
    await assertHasAssist('var i = -12_345_678;');
  }

  Future<void> test_intHex_evenNumberOfDigits() async {
    await resolveTestCode('var i = /*caret*/0x123456;');
    await assertHasAssist('var i = 0x12_34_56;');
  }

  Future<void> test_intHex_existingSeparators() async {
    await resolveTestCode('var i = /*caret*/0X1___234__5_6;');
    await assertHasAssist('var i = 0X12_34_56;');
  }

  Future<void> test_intHex_existingSeparators_correct() async {
    await resolveTestCode('var i = /*caret*/0x12_34_56;');
    await assertNoAssist();
  }

  Future<void> test_intHex_threeDigits() async {
    await resolveTestCode('var i = /*caret*/0x123;');
    await assertNoAssist();
  }

  Future<void> test_intHex_upperCase() async {
    await resolveTestCode('var i = /*caret*/0X123456;');
    await assertHasAssist('var i = 0X12_34_56;');
  }
}
