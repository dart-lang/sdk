// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


bool parseDoubleThrowsBadNumberFormatException(str) {
  try {
    Math.parseDouble(str);
    return false;
  } catch (BadNumberFormatException e) {
    return true;
  }
}

void main() {
  Expect.equals(499.0, Math.parseDouble("499"));
  Expect.equals(499.0, Math.parseDouble("499.0"));
  Expect.equals(499.0, Math.parseDouble("499.0"));
  Expect.equals(499.0, Math.parseDouble("+499"));
  Expect.equals(-499.0, Math.parseDouble("-499"));
  Expect.equals(499.0, Math.parseDouble("   499   "));
  Expect.equals(499.0, Math.parseDouble("   +499   "));
  Expect.equals(-499.0, Math.parseDouble("   -499   "));
  Expect.equals(0.0, Math.parseDouble("0"));
  Expect.equals(0.0, Math.parseDouble("+0"));
  Expect.equals(-0.0, Math.parseDouble("-0"));
  Expect.equals(true, Math.parseDouble("-0").isNegative());
  Expect.equals(0.0, Math.parseDouble("   0   "));
  Expect.equals(0.0, Math.parseDouble("   +0   "));
  Expect.equals(-0.0, Math.parseDouble("   -0   "));
  Expect.equals(true, Math.parseDouble("   -0   ").isNegative());
  Expect.equals(1.0 * 0x1234567890, Math.parseDouble("0x1234567890"));
  Expect.equals(1.0 * -0x1234567890, Math.parseDouble("-0x1234567890"));
  Expect.equals(1.0 * 0x1234567890, Math.parseDouble("   0x1234567890   "));
  Expect.equals(1.0 * -0x1234567890, Math.parseDouble("   -0x1234567890   "));
  Expect.equals(256.0, Math.parseDouble("0x100"));
  Expect.equals(-256.0, Math.parseDouble("-0x100"));
  Expect.equals(256.0, Math.parseDouble("   0x100   "));
  Expect.equals(-256.0, Math.parseDouble("   -0x100   "));
  Expect.equals(1.0 * 0xabcdef, Math.parseDouble("0xabcdef"));
  Expect.equals(1.0 * 0xABCDEF, Math.parseDouble("0xABCDEF"));
  Expect.equals(1.0 * 0xabcdef, Math.parseDouble("0xabCDEf"));
  Expect.equals(1.0 * -0xabcdef, Math.parseDouble("-0xabcdef"));
  Expect.equals(1.0 * -0xABCDEF, Math.parseDouble("-0xABCDEF"));
  Expect.equals(1.0 * 0xabcdef, Math.parseDouble("   0xabcdef   "));
  Expect.equals(1.0 * 0xABCDEF, Math.parseDouble("   0xABCDEF   "));
  Expect.equals(1.0 * -0xabcdef, Math.parseDouble("   -0xabcdef   "));
  Expect.equals(1.0 * -0xABCDEF, Math.parseDouble("   -0xABCDEF   "));
  Expect.equals(1.0 * 0xabcdef, Math.parseDouble("0x00000abcdef"));
  Expect.equals(1.0 * 0xABCDEF, Math.parseDouble("0x00000ABCDEF"));
  Expect.equals(1.0 * -0xabcdef, Math.parseDouble("-0x00000abcdef"));
  Expect.equals(1.0 * -0xABCDEF, Math.parseDouble("-0x00000ABCDEF"));
  Expect.equals(1.0 * 0xabcdef, Math.parseDouble("   0x00000abcdef   "));
  Expect.equals(1.0 * 0xABCDEF, Math.parseDouble("   0x00000ABCDEF   "));
  Expect.equals(1.0 * -0xabcdef, Math.parseDouble("   -0x00000abcdef   "));
  Expect.equals(1.0 * -0xABCDEF, Math.parseDouble("   -0x00000ABCDEF   "));
  Expect.equals(10.0, Math.parseDouble("010"));
  Expect.equals(-10.0, Math.parseDouble("-010"));
  Expect.equals(10.0, Math.parseDouble("   010   "));
  Expect.equals(-10.0, Math.parseDouble("   -010   "));
  Expect.equals(0.1, Math.parseDouble("0.1"));
  Expect.equals(0.1, Math.parseDouble(" 0.1 "));
  Expect.equals(0.1, Math.parseDouble(" +0.1 "));
  Expect.equals(-0.1, Math.parseDouble(" -0.1 "));
  Expect.equals(0.1, Math.parseDouble(".1"));
  Expect.equals(0.1, Math.parseDouble(" .1 "));
  Expect.equals(0.1, Math.parseDouble(" +.1 "));
  Expect.equals(-0.1, Math.parseDouble(" -.1 "));
  Expect.equals(1234567.89, Math.parseDouble("1234567.89"));
  Expect.equals(1234567.89, Math.parseDouble(" 1234567.89 "));
  Expect.equals(1234567.89, Math.parseDouble(" +1234567.89 "));
  Expect.equals(-1234567.89, Math.parseDouble(" -1234567.89 "));
  Expect.equals(1234567e89, Math.parseDouble("1234567e89"));
  Expect.equals(1234567e89, Math.parseDouble(" 1234567e89 "));
  Expect.equals(1234567e89, Math.parseDouble(" +1234567e89 "));
  Expect.equals(-1234567e89, Math.parseDouble(" -1234567e89 "));
  Expect.equals(1234567.89e2, Math.parseDouble("1234567.89e2"));
  Expect.equals(1234567.89e2, Math.parseDouble(" 1234567.89e2 "));
  Expect.equals(1234567.89e2, Math.parseDouble(" +1234567.89e2 "));
  Expect.equals(-1234567.89e2, Math.parseDouble(" -1234567.89e2 "));
  Expect.equals(1234567.89e2, Math.parseDouble("1234567.89E2"));
  Expect.equals(1234567.89e2, Math.parseDouble(" 1234567.89E2 "));
  Expect.equals(1234567.89e2, Math.parseDouble(" +1234567.89E2 "));
  Expect.equals(-1234567.89e2, Math.parseDouble(" -1234567.89E2 "));
  Expect.equals(1234567.89e-2, Math.parseDouble("1234567.89e-2"));
  Expect.equals(1234567.89e-2, Math.parseDouble(" 1234567.89e-2 "));
  Expect.equals(1234567.89e-2, Math.parseDouble(" +1234567.89e-2 "));
  Expect.equals(-1234567.89e-2, Math.parseDouble(" -1234567.89e-2 "));
  // TODO(floitsch): add tests for NaN and Infinity.
  Expect.equals(false, parseDoubleThrowsBadNumberFormatException("1.5"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("1b"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" 1b "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" 1 b "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" e3 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" .e3 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("00x12"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" 00x12 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("-1b"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" -1b "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" -1 b "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("-00x12"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" -00x12 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("  -00x12 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("0x0x12"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("+ 1.5"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("- 1.5"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(""));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("   "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("5."));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" 5. "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" +5. "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" -5. "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("1234567.e2"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" 1234567.e2 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" +1234567.e2 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException(" -1234567.e2 "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("+0x1234567890"));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("   +0x1234567890   "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("   +0x100   "));
  Expect.equals(true, parseDoubleThrowsBadNumberFormatException("+0x100"));
}
