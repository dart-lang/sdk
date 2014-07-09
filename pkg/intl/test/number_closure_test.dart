// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests based on the closure number formatting tests.
 */
library number_closure_test;

import "package:intl/intl.dart";
import "package:unittest/unittest.dart";

main() {
  test("testVeryBigNumber", testVeryBigNumber);
  test("testStandardFormat", testStandardFormat);
  test("testNegativePercentage", testNegativePercentage);
  test("testCustomPercentage", testCustomPercentage);
  test("testBasicFormat", testBasicFormat);
  test("testGrouping", testGrouping);
  test("testPerMill", testPerMill);
  test("testQuotes", testQuotes);
  test("testZeros", testZeros);
  test("testExponential", testExponential);
  test("testPlusSignInExponentPart", testPlusSignInExponentPart);
  test("testApis", testApis);
  test("testLocaleSwitch", testLocaleSwitch);
}

/**
 * Test two large numbers for equality, assuming that there may be some
 * loss of precision in the less significant digits.
 */
veryBigNumberCompare(str1, str2) {
  return str1.length == str2.length &&
         str1.substring(0, 8) == str2.substring(0, 8);
}

testVeryBigNumber() {
  var str;
  var fmt;

  fmt = new NumberFormat.decimalPattern();
  str = fmt.format(1.3456E20);
  expect(veryBigNumberCompare('134,559,999,999,999,000,000', str), isTrue);

  fmt = new NumberFormat.percentPattern();
  str = fmt.format(1.3456E20);
  expect(veryBigNumberCompare('13,456,000,000,000,000,000,000%', str), isTrue);

  // TODO(alanknight): Note that this disagrees with what ICU would print
  // for this. We need significant digit support to do this properly.
  fmt = new NumberFormat.scientificPattern();
  str = fmt.format(1.3456E20);
  expect('1E20', str);

  fmt = new NumberFormat.decimalPattern();
  str = fmt.format(-1.234567890123456e306);
  expect(1 + 1 + 306 + 306 / 3, str.length);
  expect('-1,234,567,890,123,45', str.substring(0, 21));

  str = fmt.format(1 / 0);
  expect('∞', str);
  str = fmt.format(-1 / 0);
  expect('-∞', str);
}

void testStandardFormat() {
  var str;
  var fmt;
  fmt = new NumberFormat.decimalPattern();
  str = fmt.format(1234.579);
  expect('1,234.579', str);
  fmt = new NumberFormat.percentPattern();
  str = fmt.format(1234.579);
  expect('123,458%', str);
  fmt = new NumberFormat.scientificPattern();
  str = fmt.format(1234.579);
  expect('1E3', str);
}

void testNegativePercentage() {
  var str;
  var fmt = new NumberFormat('#,##0.00%');
  str = fmt.format(-1234.56);
  expect('-123,456.00%', str);

  fmt = new NumberFormat.percentPattern();
  str = fmt.format(-1234.579);
  expect('-123,458%', str);
}

void testCustomPercentage() {
  var fmt = new NumberFormat.percentPattern();
  fmt.maximumFractionDigits = 1;
  fmt.minimumFractionDigits = 1;
  var str = fmt.format(0.1291);
  expect('12.9%', str);
  fmt.maximumFractionDigits = 2;
  fmt.minimumFractionDigits = 1;
  str = fmt.format(0.129);
  expect('12.9%', str);
  fmt.maximumFractionDigits = 2;
  fmt.minimumFractionDigits = 1;
  str = fmt.format(0.12);
  expect('12.0%', str);
  fmt.maximumFractionDigits = 2;
  fmt.minimumFractionDigits = 1;
  str = fmt.format(0.12911);
  expect('12.91%', str);
}

void testBasicFormat() {
  var fmt = new NumberFormat('0.0000');
  var str = fmt.format(123.45789179565757);
  expect('123.4579', str);
}

void testGrouping() {
  var str;

  var fmt = new NumberFormat('#,###');
  str = fmt.format(1234567890);
  expect('1,234,567,890', str);
  fmt = new NumberFormat('#,####');
  str = fmt.format(1234567890);
  expect('12,3456,7890', str);

  fmt = new NumberFormat('#');
  str = fmt.format(1234567890);
  expect('1234567890', str);
}

void testPerMill() {
  var str;

  var fmt = new NumberFormat('###.###\u2030');
  str = fmt.format(0.4857);
  expect('485.7\u2030', str);
}

void testQuotes() {
  var str;

  var fmt = new NumberFormat('a\'fo\'\'o\'b#');
  str = fmt.format(123);
  expect('afo\'ob123', str);

  fmt = new NumberFormat('a\'\'b#');
  str = fmt.format(123);
  expect('a\'b123', str);

  fmt = new NumberFormat('a\'fo\'\'o\'b#');
  str = fmt.format(-123);
  expect('-afo\'ob123', str);

  fmt = new NumberFormat('a\'\'b#');
  str = fmt.format(-123);
  expect('-a\'b123', str);
}

void testZeros() {
  var str;
  var fmt;

  fmt = new NumberFormat('#.#');
  str = fmt.format(0);
  expect('0', str);
  fmt = new NumberFormat('#.');
  str = fmt.format(0);
  expect('0.', str);
  fmt = new NumberFormat('.#');
  str = fmt.format(0);
  expect('.0', str);
  fmt = new NumberFormat('#');
  str = fmt.format(0);
  expect('0', str);

  fmt = new NumberFormat('#0.#');
  str = fmt.format(0);
  expect('0', str);
  fmt = new NumberFormat('#0.');
  str = fmt.format(0);
  expect('0.', str);
  fmt = new NumberFormat('#.0');
  str = fmt.format(0);
  expect('.0', str);
  fmt = new NumberFormat('#');
  str = fmt.format(0);
  expect('0', str);
  fmt = new NumberFormat('000');
  str = fmt.format(0);
  expect('000', str);
}

void testExponential() {
  var str;
  var fmt;

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(0.01234);
  expect('1.234E-2', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(0.01234);
  expect('12.340E-03', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(0.01234);
  expect('12.34E-003', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(0.01234);
  expect('1.234E-2', str);

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(123456789);
  expect('1.2346E8', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(123456789);
  expect('12.346E07', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(123456789);
  expect('123.456789E006', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(123456789);
  expect('1.235E8', str);

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(1.23e300);
  expect('1.23E300', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(1.23e300);
  expect('12.300E299', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(1.23e300);
  expect('1.23E300', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(1.23e300);
  expect('1.23E300', str);

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(-3.141592653e-271);
  expect('-3.1416E-271', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(-3.141592653e-271);
  expect('-31.416E-272', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(-3.141592653e-271);
  expect('-314.159265E-273', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(-3.141592653e-271);
  expect('[3.142E-271]', str);

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(0);
  expect('0E0', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(0);
  expect('00.000E00', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(0);
  expect('0E000', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(0);
  expect('0E0', str);

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(-1);
  expect('-1E0', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(-1);
  expect('-10.000E-01', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(-1);
  expect('-1E000', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(-1);
  expect('[1E0]', str);

  fmt = new NumberFormat('0.####E0');
  str = fmt.format(1);
  expect('1E0', str);
  fmt = new NumberFormat('00.000E00');
  str = fmt.format(1);
  expect('10.000E-01', str);
  fmt = new NumberFormat('##0.######E000');
  str = fmt.format(1);
  expect('1E000', str);
  fmt = new NumberFormat('0.###E0;[0.###E0]');
  str = fmt.format(1);
  expect('1E0', str);

  fmt = new NumberFormat('#E0');
  str = fmt.format(12345.0);
  expect('1E4', str);
  fmt = new NumberFormat('0E0');
  str = fmt.format(12345.0);
  expect('1E4', str);
  fmt = new NumberFormat('##0.###E0');
  str = fmt.format(12345.0);
  expect('12.345E3', str);
  fmt = new NumberFormat('##0.###E0');
  str = fmt.format(12345.00001);
  expect('12.345E3', str);
  fmt = new NumberFormat('##0.###E0');
  str = fmt.format(12345);
  expect('12.345E3', str);

  fmt = new NumberFormat('##0.####E0');
  str = fmt.format(789.12345e-9);
  fmt = new NumberFormat('##0.####E0');
  str = fmt.format(780e-9);
  expect('780E-9', str);
  fmt = new NumberFormat('.###E0');
  str = fmt.format(45678.0);
  expect('.457E5', str);
  fmt = new NumberFormat('.###E0');
  str = fmt.format(0);
  expect('.0E0', str);

  fmt = new NumberFormat('#E0');
  str = fmt.format(45678000);
  expect('5E7', str);
  fmt = new NumberFormat('##E0');
  str = fmt.format(45678000);
  expect('46E6', str);
  fmt = new NumberFormat('####E0');
  str = fmt.format(45678000);
  expect('4568E4', str);
  fmt = new NumberFormat('0E0');
  str = fmt.format(45678000);
  expect('5E7', str);
  fmt = new NumberFormat('00E0');
  str = fmt.format(45678000);
  expect('46E6', str);
  fmt = new NumberFormat('000E0');
  str = fmt.format(45678000);
  expect('457E5', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(0.0000123);
  expect('12E-6', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(0.000123);
  expect('123E-6', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(0.00123);
  expect('1E-3', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(0.0123);
  expect('12E-3', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(0.123);
  expect('123E-3', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(1.23);
  expect('1E0', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(12.3);
  expect('12E0', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(123.0);
  expect('123E0', str);
  fmt = new NumberFormat('###E0');
  str = fmt.format(1230.0);
  expect('1E3', str);
}

void testPlusSignInExponentPart() {
  var fmt;
  fmt = new NumberFormat('0E+0');
  var str = fmt.format(45678000);
  expect('5E+7', str);
}

void testApis() {
  var fmt;
  var str;

  fmt = new NumberFormat('#,###');
  str = fmt.format(1234567890);
  expect('1,234,567,890', str);
}

testLocaleSwitch() {
  Intl.withLocale("fr", verifyFrenchLocale);
}

void verifyFrenchLocale() {
  var fmt = new NumberFormat('#,###');
  var str = fmt.format(1234567890);
  expect('1\u00a0234\u00a0567\u00a0890', str);
}
