// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Pass expected value and then decimal literal value in a double context.
void expectDouble(double expectedValue, double actualValue) {
  Expect.identical(expectedValue, actualValue);
}

// Some exact powers of two as double values.
double p2_8 = 256.0;
double p2_30 = 1073741824.0;
double p2_31 = 2147483648.0;
double p2_32 = 4294967296.0;
double p2_52 = 4503599627370496.0;
double p2_53 = 9007199254740992.0;
double p2_54 = 18014398509481984.0;
double p2_62 = 4611686018427387904.0;
double p2_63 = 9223372036854775808.0;
double p2_64 = 18446744073709551616.0;
double maxValue = 1.7976931348623157e+308;

main() {
  expectDouble(0.0, 0);
  expectDouble(1.0, 1);
  expectDouble(0.0, 00);
  expectDouble(1.0, 01);
  expectDouble(p2_8 - 1, 255);
  expectDouble(p2_8, 256);
  expectDouble(p2_8 + 1, 257);
  expectDouble(p2_30 - 1, 1073741823);
  expectDouble(p2_30, 1073741824);
  expectDouble(p2_30 + 1, 1073741825);
  expectDouble(p2_31 - 1, 2147483647);
  expectDouble(p2_31, 2147483648);
  expectDouble(p2_31 + 1, 2147483649);
  expectDouble(p2_32 - 1, 4294967295);
  expectDouble(p2_32, 4294967296);
  expectDouble(p2_32 + 1, 4294967297);
  expectDouble(p2_52 - 1, 4503599627370495);
  expectDouble(p2_52, 4503599627370496);
  expectDouble(p2_52 + 1, 4503599627370497);
  expectDouble(p2_53 - 1, 9007199254740991);
  expectDouble(p2_53, 9007199254740992);
  expectDouble(p2_53 + 2, 9007199254740994);
  expectDouble(p2_54 - 2, 18014398509481982);
  expectDouble(p2_54, 18014398509481984);
  expectDouble(p2_54 + 4, 18014398509481988);
  expectDouble(p2_62, 4611686018427387904);
  expectDouble(p2_63, 9223372036854775808);
  expectDouble(p2_64, 18446744073709551616);
  expectDouble(maxValue,
      179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368);

  expectDouble(-0.0, -0);
  expectDouble(-1.0, -1);
  expectDouble(-0.0, -00);
  expectDouble(-1.0, -01);
  expectDouble(-(p2_8 - 1), -255);
  expectDouble(-(p2_8), -256);
  expectDouble(-(p2_8 + 1), -257);
  expectDouble(-(p2_30 - 1), -1073741823);
  expectDouble(-(p2_30), -1073741824);
  expectDouble(-(p2_30 + 1), -1073741825);
  expectDouble(-(p2_31 - 1), -2147483647);
  expectDouble(-(p2_31), -2147483648);
  expectDouble(-(p2_31 + 1), -2147483649);
  expectDouble(-(p2_32 - 1), -4294967295);
  expectDouble(-(p2_32), -4294967296);
  expectDouble(-(p2_32 + 1), -4294967297);
  expectDouble(-(p2_52 - 1), -4503599627370495);
  expectDouble(-(p2_52), -4503599627370496);
  expectDouble(-(p2_52 + 1), -4503599627370497);
  expectDouble(-(p2_53 - 1), -9007199254740991);
  expectDouble(-(p2_53), -9007199254740992);
  expectDouble(-(p2_53 + 2), -9007199254740994);
  expectDouble(-(p2_54 - 2), -18014398509481982);
  expectDouble(-(p2_54), -18014398509481984);
  expectDouble(-(p2_54 + 4), -18014398509481988);
  expectDouble(-(p2_62), -4611686018427387904);
  expectDouble(-(p2_63), -9223372036854775808);
  expectDouble(-(p2_64), -18446744073709551616);
  expectDouble(-maxValue,
      -179769313486231570814527423731704356798070567525844996598917476803157260780028538760589558632766878171540458953514382464234321326889464182768467546703537516986049910576551282076245490090389328944075868508455133942304583236903222948165808559332123348274797826204144723168738177180919299881250404026184124858368);

  expectDouble(0.0, 0x0);
  expectDouble(1.0, 0x1);
  expectDouble(0.0, 0x00);
  expectDouble(1.0, 0x01);
  expectDouble(p2_8 - 1, 0xff);
  expectDouble(p2_8, 0x100);
  expectDouble(p2_8 + 1, 0x101);
  expectDouble(p2_30 - 1, 0x3fffffff);
  expectDouble(p2_30, 0x40000000);
  expectDouble(p2_30 + 1, 0x40000001);
  expectDouble(p2_31 - 1, 0x7fffffff);
  expectDouble(p2_31, 0x80000000);
  expectDouble(p2_31 + 1, 0x80000001);
  expectDouble(p2_32 - 1, 0xffffffff);
  expectDouble(p2_32, 0x100000000);
  expectDouble(p2_32 + 1, 0x100000001);
  expectDouble(p2_52 - 1, 0xfffffffffffff);
  expectDouble(p2_52, 0x10000000000000);
  expectDouble(p2_52 + 1, 0x10000000000001);
  expectDouble(p2_53 - 1, 0x1fffffffffffff);
  expectDouble(p2_53, 0x20000000000000);
  expectDouble(p2_53 + 2, 0x20000000000002);
  expectDouble(p2_54 - 2, 0x3ffffffffffffe);
  expectDouble(p2_54, 0x40000000000000);
  expectDouble(p2_54 + 4, 0x40000000000004);
  expectDouble(p2_62, 0x4000000000000000);
  expectDouble(p2_63, 0x8000000000000000);
  expectDouble(p2_64, 0x10000000000000000);
  expectDouble(maxValue,
      0xfffffffffffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);

  expectDouble(-0.0, -0x0);
  expectDouble(-1.0, -0x1);
  expectDouble(-0.0, -0x00);
  expectDouble(-1.0, -0x01);
  expectDouble(-(p2_8 - 1), -0xff);
  expectDouble(-(p2_8), -0x100);
  expectDouble(-(p2_8 + 1), -0x101);
  expectDouble(-(p2_30 - 1), -0x3fffffff);
  expectDouble(-(p2_30), -0x40000000);
  expectDouble(-(p2_30 + 1), -0x40000001);
  expectDouble(-(p2_31 - 1), -0x7fffffff);
  expectDouble(-(p2_31), -0x80000000);
  expectDouble(-(p2_31 + 1), -0x80000001);
  expectDouble(-(p2_32 - 1), -0xffffffff);
  expectDouble(-(p2_32), -0x100000000);
  expectDouble(-(p2_32 + 1), -0x100000001);
  expectDouble(-(p2_52 - 1), -0xfffffffffffff);
  expectDouble(-(p2_52), -0x10000000000000);
  expectDouble(-(p2_52 + 1), -0x10000000000001);
  expectDouble(-(p2_53 - 1), -0x1fffffffffffff);
  expectDouble(-(p2_53), -0x20000000000000);
  expectDouble(-(p2_53 + 2), -0x20000000000002);
  expectDouble(-(p2_54 - 2), -0x3ffffffffffffe);
  expectDouble(-(p2_54), -0x40000000000000);
  expectDouble(-(p2_54 + 4), -0x40000000000004);
  expectDouble(-(p2_62), -0x4000000000000000);
  expectDouble(-(p2_63), -0x8000000000000000);
  expectDouble(-(p2_64), -0x10000000000000000);
  expectDouble(-maxValue,
      -0xfffffffffffff800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000);
}
