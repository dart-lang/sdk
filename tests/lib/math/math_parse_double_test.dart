// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// We temporarily test both the new math library and the old Math
// class. This can easily be simplified once we get rid of the Math
// class entirely.
library math_parse_double_test;

import "package:expect/expect.dart";

void parseDoubleThrowsFormatException(str) {
  Expect.throws(() => double.parse(str), (e) => e is FormatException);
}

void runTest(double expected, String input) {
  Expect.equals(expected, double.parse(input));
  Expect.equals(expected, double.parse(" $input "));
  Expect.equals(expected, double.parse(" $input"));
  Expect.equals(expected, double.parse("$input "));
  Expect.equals(expected, double.parse("+$input"));
  Expect.equals(expected, double.parse(" +$input "));
  Expect.equals(expected, double.parse("+$input "));
  Expect.equals(expected, double.parse("\xA0 $input\xA0 "));
  Expect.equals(expected, double.parse(" \xA0$input"));
  Expect.equals(expected, double.parse("$input \xA0"));
  Expect.equals(expected, double.parse("\xA0 +$input\xA0 "));
  Expect.equals(expected, double.parse("+$input\xA0 "));
  Expect.equals(expected, double.parse("\u205F $input\u205F "));
  Expect.equals(expected, double.parse("$input \u2006"));
  Expect.equals(expected, double.parse("\u1680 +$input\u1680 "));
  Expect.equals(-expected, double.parse("-$input"));
  Expect.equals(-expected, double.parse(" -$input "));
  Expect.equals(-expected, double.parse("-$input "));
  Expect.equals(-expected, double.parse("\xA0 -$input\xA0 "));
  Expect.equals(-expected, double.parse("-$input\xA0 "));
  Expect.equals(-expected, double.parse("\u1680 -$input\u1680 "));
}

final TESTS = [
  [499.0, "499"],
  [499.0, "499."],
  [499.0, "499.0"],
  [0.0, "0"],
  [0.0, ".0"],
  [0.0, "0."],
  [0.1, "0.1"],
  [0.1, ".1"],
  [10.0, "010"],
  [1.5, "1.5"],
  [1.5, "001.5"],
  [1.5, "1.500"],
  [1234567.89, "1234567.89"],
  [1234567e89, "1234567e89"],
  [1234567.89e2, "1234567.89e2"],
  [1234567.89e2, "1234567.89e+2"],
  [1234567.89e-2, "1234567.89e-2"],
  [5.0, "5"],
  [123456700.0, "1234567.e2"],
  [123456700.0, "1234567.e+2"],
  [double.INFINITY, "Infinity"],
  [5e-324, "5e-324"], // min-pos.
  // Same, without exponential.
  [
    0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004940656458412465441765687928682213723650598026143247644255856825006755072702087518652998363616359923797965646954457177309266567103559397963987747960107818781263007131903114045278458171678489821036887186360569987307230500063874091535649843873124733972731696151400317153853980741262385655911710266585566867681870395603106249319452715914924553293054565444011274801297099995419319894090804165633245247571478690147267801593552386115501348035264934720193790268107107491703332226844753335720832431936092382893458368060106011506169809753078342277318329247904982524730776375927247874656084778203734469699533647017972677717585125660551199131504891101451037862738167250955837389733598993664809941164205702637090279242767544565229087538682506419718265533447265625,
    "0.000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004940656458412465441765687928682213723650598026143247644255856825006755072702087518652998363616359923797965646954457177309266567103559397963987747960107818781263007131903114045278458171678489821036887186360569987307230500063874091535649843873124733972731696151400317153853980741262385655911710266585566867681870395603106249319452715914924553293054565444011274801297099995419319894090804165633245247571478690147267801593552386115501348035264934720193790268107107491703332226844753335720832431936092382893458368060106011506169809753078342277318329247904982524730776375927247874656084778203734469699533647017972677717585125660551199131504891101451037862738167250955837389733598993664809941164205702637090279242767544565229087538682506419718265533447265625"
  ],
  [0.0, "2e-324"], // underflow 0.0
  [0.9999999999999999, "0.9999999999999999"], // max below 1
  [1.0, "1.00000000000000005"], // 1.0
  [1.0000000000000002, "1.0000000000000002"], // min above 1
  [2147483647.0, "2147483647"], // max int32
  [2147483647.0000002, "2147483647.0000002"], // min not int32
  [2147483648.0, "2147483648"], // min int not int32
  [4295967295.0, "4295967295"], // max uint32
  [4295967295.000001, "4295967295.000001"], // min not uint-32
  [4295967296.0, "4295967296"], // min int not-uint32
  [1.7976931348623157e+308, "1.7976931348623157e+308"], // Max finit
  [1.7976931348623157e+308, "1.7976931348623158e+308"], // Max finit
  [double.INFINITY, "1.7976931348623159e+308"], // Infinity
  [.049999999999999994, ".049999999999999994"], // not 0.5
  [.05, ".04999999999999999935"],
  [4503599627370498.0, "4503599627370497.5"],
  [1.2345678901234568e+39, "1234567890123456898981341324213421342134"],
  [9.87291183742987e+24, "9872911837429871193379121"],
  [1e21, "1e+21"],
];

void main() {
  for (var test in TESTS) {
    runTest(test[0], test[1]);
  }

  Expect.equals(true, double.parse("-0").isNegative);
  Expect.equals(true, double.parse("   -0   ").isNegative);
  Expect.equals(true, double.parse("\xA0   -0   \xA0").isNegative);
  Expect.isTrue(double.parse("NaN").isNaN);
  Expect.isTrue(double.parse("-NaN").isNaN);
  Expect.isTrue(double.parse("+NaN").isNaN);
  Expect.isTrue(double.parse("NaN ").isNaN);
  Expect.isTrue(double.parse("-NaN ").isNaN);
  Expect.isTrue(double.parse("+NaN ").isNaN);
  Expect.isTrue(double.parse(" NaN ").isNaN);
  Expect.isTrue(double.parse(" -NaN ").isNaN);
  Expect.isTrue(double.parse(" +NaN ").isNaN);
  Expect.isTrue(double.parse(" NaN").isNaN);
  Expect.isTrue(double.parse(" -NaN").isNaN);
  Expect.isTrue(double.parse(" +NaN").isNaN);
  Expect.isTrue(double.parse("NaN\xA0").isNaN);
  Expect.isTrue(double.parse("-NaN\xA0").isNaN);
  Expect.isTrue(double.parse("+NaN\xA0").isNaN);
  Expect.isTrue(double.parse(" \xA0NaN\xA0").isNaN);
  Expect.isTrue(double.parse(" \xA0-NaN\xA0").isNaN);
  Expect.isTrue(double.parse(" \xA0+NaN\xA0").isNaN);
  Expect.isTrue(double.parse(" \xA0NaN").isNaN);
  Expect.isTrue(double.parse(" \xA0-NaN").isNaN);
  Expect.isTrue(double.parse(" \xA0+NaN").isNaN);

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
  parseDoubleThrowsFormatException("+0x1234567890");
  parseDoubleThrowsFormatException("   +0x1234567890   ");
  parseDoubleThrowsFormatException("   +0x100   ");
  parseDoubleThrowsFormatException("+0x100");
  parseDoubleThrowsFormatException("0x1234567890");
  parseDoubleThrowsFormatException("-0x1234567890");
  parseDoubleThrowsFormatException("   0x1234567890   ");
  parseDoubleThrowsFormatException("   -0x1234567890   ");
  parseDoubleThrowsFormatException("0x100");
  parseDoubleThrowsFormatException("-0x100");
  parseDoubleThrowsFormatException("   0x100   ");
  parseDoubleThrowsFormatException("   -0x100   ");
  parseDoubleThrowsFormatException("0xabcdef");
  parseDoubleThrowsFormatException("0xABCDEF");
  parseDoubleThrowsFormatException("0xabCDEf");
  parseDoubleThrowsFormatException("-0xabcdef");
  parseDoubleThrowsFormatException("-0xABCDEF");
  parseDoubleThrowsFormatException("   0xabcdef   ");
  parseDoubleThrowsFormatException("   0xABCDEF   ");
  parseDoubleThrowsFormatException("   -0xabcdef   ");
  parseDoubleThrowsFormatException("   -0xABCDEF   ");
  parseDoubleThrowsFormatException("0x00000abcdef");
  parseDoubleThrowsFormatException("0x00000ABCDEF");
  parseDoubleThrowsFormatException("-0x00000abcdef");
  parseDoubleThrowsFormatException("-0x00000ABCDEF");
  parseDoubleThrowsFormatException("   0x00000abcdef   ");
  parseDoubleThrowsFormatException("   0x00000ABCDEF   ");
  parseDoubleThrowsFormatException("   -0x00000abcdef   ");
  parseDoubleThrowsFormatException("   -0x00000ABCDEF   ");
  parseDoubleThrowsFormatException("   -INFINITY   ");
  parseDoubleThrowsFormatException("   NAN   ");
  parseDoubleThrowsFormatException("   inf   ");
  parseDoubleThrowsFormatException("   nan   ");
}
