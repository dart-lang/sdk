// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We temporarily test both the new math library and the old Math
// class. This can easily be simplified once we get rid of the Math
// class entirely.
library math_parse_double_test;

import 'dart:math';

void parseDoubleThrowsFormatException(str) {
  Expect.throws(() => parseDouble(str), (e) => e is FormatException);
}

void main() {
  Expect.equals(499.0, parseDouble("499"));
  Expect.equals(499.0, parseDouble("499.0"));
  Expect.equals(499.0, parseDouble("499.0"));
  Expect.equals(499.0, parseDouble("+499"));
  Expect.equals(-499.0, parseDouble("-499"));
  Expect.equals(499.0, parseDouble("   499   "));
  Expect.equals(499.0, parseDouble("   +499   "));
  Expect.equals(-499.0, parseDouble("   -499   "));
  Expect.equals(0.0, parseDouble("0"));
  Expect.equals(0.0, parseDouble("+0"));
  Expect.equals(-0.0, parseDouble("-0"));
  Expect.equals(true, parseDouble("-0").isNegative());
  Expect.equals(0.0, parseDouble("   0   "));
  Expect.equals(0.0, parseDouble("   +0   "));
  Expect.equals(-0.0, parseDouble("   -0   "));
  Expect.equals(true, parseDouble("   -0   ").isNegative());
  Expect.equals(1.0 * 0x1234567890, parseDouble("0x1234567890"));
  Expect.equals(1.0 * -0x1234567890, parseDouble("-0x1234567890"));
  Expect.equals(1.0 * 0x1234567890, parseDouble("   0x1234567890   "));
  Expect.equals(1.0 * -0x1234567890, parseDouble("   -0x1234567890   "));
  Expect.equals(256.0, parseDouble("0x100"));
  Expect.equals(-256.0, parseDouble("-0x100"));
  Expect.equals(256.0, parseDouble("   0x100   "));
  Expect.equals(-256.0, parseDouble("   -0x100   "));
  Expect.equals(1.0 * 0xabcdef, parseDouble("0xabcdef"));
  Expect.equals(1.0 * 0xABCDEF, parseDouble("0xABCDEF"));
  Expect.equals(1.0 * 0xabcdef, parseDouble("0xabCDEf"));
  Expect.equals(1.0 * -0xabcdef, parseDouble("-0xabcdef"));
  Expect.equals(1.0 * -0xABCDEF, parseDouble("-0xABCDEF"));
  Expect.equals(1.0 * 0xabcdef, parseDouble("   0xabcdef   "));
  Expect.equals(1.0 * 0xABCDEF, parseDouble("   0xABCDEF   "));
  Expect.equals(1.0 * -0xabcdef, parseDouble("   -0xabcdef   "));
  Expect.equals(1.0 * -0xABCDEF, parseDouble("   -0xABCDEF   "));
  Expect.equals(1.0 * 0xabcdef, parseDouble("0x00000abcdef"));
  Expect.equals(1.0 * 0xABCDEF, parseDouble("0x00000ABCDEF"));
  Expect.equals(1.0 * -0xabcdef, parseDouble("-0x00000abcdef"));
  Expect.equals(1.0 * -0xABCDEF, parseDouble("-0x00000ABCDEF"));
  Expect.equals(1.0 * 0xabcdef, parseDouble("   0x00000abcdef   "));
  Expect.equals(1.0 * 0xABCDEF, parseDouble("   0x00000ABCDEF   "));
  Expect.equals(1.0 * -0xabcdef, parseDouble("   -0x00000abcdef   "));
  Expect.equals(1.0 * -0xABCDEF, parseDouble("   -0x00000ABCDEF   "));
  Expect.equals(10.0, parseDouble("010"));
  Expect.equals(-10.0, parseDouble("-010"));
  Expect.equals(10.0, parseDouble("   010   "));
  Expect.equals(-10.0, parseDouble("   -010   "));
  Expect.equals(0.1, parseDouble("0.1"));
  Expect.equals(0.1, parseDouble(" 0.1 "));
  Expect.equals(0.1, parseDouble(" +0.1 "));
  Expect.equals(-0.1, parseDouble(" -0.1 "));
  Expect.equals(0.1, parseDouble(".1"));
  Expect.equals(0.1, parseDouble(" .1 "));
  Expect.equals(0.1, parseDouble(" +.1 "));
  Expect.equals(-0.1, parseDouble(" -.1 "));
  Expect.equals(1.5, parseDouble("1.5"));
  Expect.equals(1234567.89, parseDouble("1234567.89"));
  Expect.equals(1234567.89, parseDouble(" 1234567.89 "));
  Expect.equals(1234567.89, parseDouble(" +1234567.89 "));
  Expect.equals(-1234567.89, parseDouble(" -1234567.89 "));
  Expect.equals(1234567e89, parseDouble("1234567e89"));
  Expect.equals(1234567e89, parseDouble(" 1234567e89 "));
  Expect.equals(1234567e89, parseDouble(" +1234567e89 "));
  Expect.equals(-1234567e89, parseDouble(" -1234567e89 "));
  Expect.equals(1234567.89e2, parseDouble("1234567.89e2"));
  Expect.equals(1234567.89e2, parseDouble(" 1234567.89e2 "));
  Expect.equals(1234567.89e2, parseDouble(" +1234567.89e2 "));
  Expect.equals(-1234567.89e2, parseDouble(" -1234567.89e2 "));
  Expect.equals(1234567.89e2, parseDouble("1234567.89E2"));
  Expect.equals(1234567.89e2, parseDouble(" 1234567.89E2 "));
  Expect.equals(1234567.89e2, parseDouble(" +1234567.89E2 "));
  Expect.equals(-1234567.89e2, parseDouble(" -1234567.89E2 "));
  Expect.equals(1234567.89e-2, parseDouble("1234567.89e-2"));
  Expect.equals(1234567.89e-2, parseDouble(" 1234567.89e-2 "));
  Expect.equals(1234567.89e-2, parseDouble(" +1234567.89e-2 "));
  Expect.equals(-1234567.89e-2, parseDouble(" -1234567.89e-2 "));
  // TODO(floitsch): add tests for NaN and Infinity.
  parseDoubleThrowsFormatException("1b");
  parseDoubleThrowsFormatException(" 1b ");
  parseDoubleThrowsFormatException(" 1 b ");
  parseDoubleThrowsFormatException(" e3 ");
  parseDoubleThrowsFormatException(" .e3 ");
  parseDoubleThrowsFormatException("00x12");
  parseDoubleThrowsFormatException(" 00x12 ");
  parseDoubleThrowsFormatException("-1b");
  parseDoubleThrowsFormatException(" -1b ");
  parseDoubleThrowsFormatException(" -1 b ");
  parseDoubleThrowsFormatException("-00x12");
  parseDoubleThrowsFormatException(" -00x12 ");
  parseDoubleThrowsFormatException("  -00x12 ");
  parseDoubleThrowsFormatException("0x0x12");
  parseDoubleThrowsFormatException("+ 1.5");
  parseDoubleThrowsFormatException("- 1.5");
  parseDoubleThrowsFormatException("");
  parseDoubleThrowsFormatException("   ");
  parseDoubleThrowsFormatException("5.");
  parseDoubleThrowsFormatException(" 5. ");
  parseDoubleThrowsFormatException(" +5. ");
  parseDoubleThrowsFormatException(" -5. ");
  parseDoubleThrowsFormatException("1234567.e2");
  parseDoubleThrowsFormatException(" 1234567.e2 ");
  parseDoubleThrowsFormatException(" +1234567.e2 ");
  parseDoubleThrowsFormatException(" -1234567.e2 ");
  parseDoubleThrowsFormatException("+0x1234567890");
  parseDoubleThrowsFormatException("   +0x1234567890   ");
  parseDoubleThrowsFormatException("   +0x100   ");
  parseDoubleThrowsFormatException("+0x100");
}
