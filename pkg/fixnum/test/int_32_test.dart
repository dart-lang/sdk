// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library Int32test;
import 'package:fixnum/fixnum.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("isX tests", () {
    test("isEven", () {
      expect((-Int32.ONE).isEven, false);
      expect(Int32.ZERO.isEven, true);
      expect(Int32.ONE.isEven, false);
      expect(Int32.TWO.isEven, true);
    });
    test("isMaxValue", () {
      expect(Int32.MIN_VALUE.isMaxValue, false);
      expect(Int32.ZERO.isMaxValue, false);
      expect(Int32.MAX_VALUE.isMaxValue, true);
    });
    test("isMinValue", () {
      expect(Int32.MIN_VALUE.isMinValue, true);
      expect(Int32.ZERO.isMinValue, false);
      expect(Int32.MAX_VALUE.isMinValue, false);
    });
    test("isNegative", () {
      expect(Int32.MIN_VALUE.isNegative, true);
      expect(Int32.ZERO.isNegative, false);
      expect(Int32.ONE.isNegative, false);
    });
    test("isOdd", () {
      expect((-Int32.ONE).isOdd, true);
      expect(Int32.ZERO.isOdd, false);
      expect(Int32.ONE.isOdd, true);
      expect(Int32.TWO.isOdd, false);
    });
    test("isZero", () {
      expect(Int32.MIN_VALUE.isZero, false);
      expect(Int32.ZERO.isZero, true);
      expect(Int32.MAX_VALUE.isZero, false);
    });
    test("bitLength", () {
      expect(new Int32(-2).bitLength, 1);
      expect((-Int32.ONE).bitLength, 0);
      expect(Int32.ZERO.bitLength, 0);
      expect(Int32.ONE.bitLength, 1);
      expect(new Int32(2).bitLength, 2);
      expect(Int32.MAX_VALUE.bitLength, 31);
      expect(Int32.MIN_VALUE.bitLength, 31);
    });
  });

  group("arithmetic operators", () {
    Int32 n1 = new Int32(1234);
    Int32 n2 = new Int32(9876);
    Int32 n3 = new Int32(-1234);
    Int32 n4 = new Int32(-9876);
    Int32 n5 = new Int32(0x12345678);
    Int32 n6 = new Int32(0x22222222);

    test("+", () {
      expect(n1 + n2, new Int32(11110));
      expect(n3 + n2, new Int32(8642));
      expect(n3 + n4, new Int32(-11110));
      expect(Int32.MAX_VALUE + 1, Int32.MIN_VALUE);
      expect(() => new Int32(17) + null, throws);
    });

    test("-", () {
      expect(n1 - n2, new Int32(-8642));
      expect(n3 - n2, new Int32(-11110));
      expect(n3 - n4, new Int32(8642));
      expect(Int32.MIN_VALUE - 1, Int32.MAX_VALUE);
      expect(() => new Int32(17) - null, throws);
    });

    test("unary -", () {
      expect(-n1, new Int32(-1234));
      expect(-Int32.ZERO, Int32.ZERO);
    });

    test("*", () {
      expect(n1 * n2, new Int32(12186984));
      expect(n2 * n3, new Int32(-12186984));
      expect(n3 * n3, new Int32(1522756));
      expect(n3 * n2, new Int32(-12186984));
      expect(new Int32(0x12345678) * new Int32(0x22222222),
          new Int32(-899716112));
      expect((new Int32(123456789) * new Int32(987654321)),
          new Int32(-67153019));
      expect(new Int32(0x12345678) * new Int64(0x22222222),
          new Int64.fromInts(0x026D60DC, 0xCA5F6BF0));
      expect((new Int32(123456789) * 987654321),
          new Int32(-67153019));
      expect(() => new Int32(17) * null, throws);
    });

    test("~/", () {
      expect(new Int32(829893893) ~/ new Int32(1919), new Int32(432461));
      expect(new Int32(0x12345678) ~/ new Int32(0x22),
          new Int32(0x12345678 ~/ 0x22));
      expect(new Int32(829893893) ~/ new Int64(1919), new Int32(432461));
      expect(new Int32(0x12345678) ~/ new Int64(0x22),
          new Int32(0x12345678 ~/ 0x22));
      expect(new Int32(829893893) ~/ 1919, new Int32(432461));
      expect(() => new Int32(17) ~/ Int32.ZERO, throws);
      expect(() => new Int32(17) ~/ null, throws);
    });

    test("%", () {
      expect(new Int32(0x12345678) % new Int32(0x22),
          new Int32(0x12345678 % 0x22));
      expect(new Int32(0x12345678) % new Int64(0x22),
          new Int32(0x12345678 % 0x22));
      expect(() => new Int32(17) % null, throws);
    });

    test("remainder", () {
      expect(new Int32(0x12345678).remainder(new Int32(0x22)),
          new Int32(0x12345678.remainder(0x22)));
      expect(new Int32(0x12345678).remainder(new Int32(-0x22)),
          new Int32(0x12345678.remainder(-0x22)));
      expect(new Int32(-0x12345678).remainder(new Int32(-0x22)),
          new Int32(-0x12345678.remainder(-0x22)));
      expect(new Int32(-0x12345678).remainder(new Int32(0x22)),
          new Int32(-0x12345678.remainder(0x22)));
      expect(new Int32(0x12345678).remainder(new Int64(0x22)),
          new Int32(0x12345678.remainder(0x22)));
      expect(() => new Int32(17).remainder(null), throws);
    });

    test("clamp", () {
      Int32 val = new Int32(17);
      expect(val.clamp(20, 30), new Int32(20));
      expect(val.clamp(10, 20), new Int32(17));
      expect(val.clamp(10, 15), new Int32(15));

      expect(val.clamp(new Int32(20), new Int32(30)), new Int32(20));
      expect(val.clamp(new Int32(10), new Int32(20)), new Int32(17));
      expect(val.clamp(new Int32(10), new Int32(15)), new Int32(15));

      expect(val.clamp(new Int64(20), new Int64(30)), new Int32(20));
      expect(val.clamp(new Int64(10), new Int64(20)), new Int32(17));
      expect(val.clamp(new Int64(10), new Int64(15)), new Int32(15));
      expect(val.clamp(Int64.MIN_VALUE, new Int64(30)), new Int32(17));
      expect(val.clamp(new Int64(10), Int64.MAX_VALUE), new Int32(17));

      expect(() => val.clamp(1, 'b'), throwsA(isArgumentError));
      expect(() => val.clamp('a', 1), throwsA(isArgumentError));
    });
  });

  group("comparison operators", () {
    test("<", () {
      expect(new Int32(17) < new Int32(18), true);
      expect(new Int32(17) < new Int32(17), false);
      expect(new Int32(17) < new Int32(16), false);
      expect(new Int32(17) < new Int64(18), true);
      expect(new Int32(17) < new Int64(17), false);
      expect(new Int32(17) < new Int64(16), false);
      expect(Int32.MIN_VALUE < Int32.MAX_VALUE, true);
      expect(Int32.MAX_VALUE < Int32.MIN_VALUE, false);
      expect(() => new Int32(17) < null, throws);
    });

    test("<=", () {
      expect(new Int32(17) <= new Int32(18), true);
      expect(new Int32(17) <= new Int32(17), true);
      expect(new Int32(17) <= new Int32(16), false);
      expect(new Int32(17) <= new Int64(18), true);
      expect(new Int32(17) <= new Int64(17), true);
      expect(new Int32(17) <= new Int64(16), false);
      expect(Int32.MIN_VALUE <= Int32.MAX_VALUE, true);
      expect(Int32.MAX_VALUE <= Int32.MIN_VALUE, false);
      expect(() => new Int32(17) <= null, throws);
    });

    test("==", () {
      expect(new Int32(17) == new Int32(18), false);
      expect(new Int32(17) == new Int32(17), true);
      expect(new Int32(17) == new Int32(16), false);
      expect(new Int32(17) == new Int64(18), false);
      expect(new Int32(17) == new Int64(17), true);
      expect(new Int32(17) == new Int64(16), false);
      expect(Int32.MIN_VALUE == Int32.MAX_VALUE, false);
      expect(new Int32(17) == new Object(), false);
      expect(new Int32(17) == null, false);
    });

    test(">=", () {
      expect(new Int32(17) >= new Int32(18), false);
      expect(new Int32(17) >= new Int32(17), true);
      expect(new Int32(17) >= new Int32(16), true);
      expect(new Int32(17) >= new Int64(18), false);
      expect(new Int32(17) >= new Int64(17), true);
      expect(new Int32(17) >= new Int64(16), true);
      expect(Int32.MIN_VALUE >= Int32.MAX_VALUE, false);
      expect(Int32.MAX_VALUE >= Int32.MIN_VALUE, true);
      expect(() => new Int32(17) >= null, throws);
    });

    test(">", () {
      expect(new Int32(17) > new Int32(18), false);
      expect(new Int32(17) > new Int32(17), false);
      expect(new Int32(17) > new Int32(16), true);
      expect(new Int32(17) > new Int64(18), false);
      expect(new Int32(17) > new Int64(17), false);
      expect(new Int32(17) > new Int64(16), true);
      expect(Int32.MIN_VALUE > Int32.MAX_VALUE, false);
      expect(Int32.MAX_VALUE > Int32.MIN_VALUE, true);
      expect(() => new Int32(17) > null, throws);
    });
  });

  group("bitwise operators", () {
    test("&", () {
      expect(new Int32(0x12345678) & new Int32(0x22222222),
          new Int32(0x12345678 & 0x22222222));
      expect(new Int32(0x12345678) & new Int64(0x22222222),
          new Int64(0x12345678 & 0x22222222));
      expect(() => new Int32(17) & null, throwsArgumentError);
    });

    test("|", () {
      expect(new Int32(0x12345678) | new Int32(0x22222222),
          new Int32(0x12345678 | 0x22222222));
      expect(new Int32(0x12345678) | new Int64(0x22222222),
          new Int64(0x12345678 | 0x22222222));
      expect(() => new Int32(17) | null, throws);
    });

    test("^", () {
      expect(new Int32(0x12345678) ^ new Int32(0x22222222),
          new Int32(0x12345678 ^ 0x22222222));
      expect(new Int32(0x12345678) ^ new Int64(0x22222222),
          new Int64(0x12345678 ^ 0x22222222));
      expect(() => new Int32(17) ^ null, throws);
    });

    test("~", () {
      expect(~(new Int32(0x12345678)), new Int32(~0x12345678));
      expect(-(new Int32(0x12345678)), new Int64(-0x12345678));
    });
  });

  group("bitshift operators", () {
    test("<<", () {
      expect(new Int32(0x12345678) << 7, new Int32(0x12345678 << 7));
      expect(() => new Int32(17) << -1, throwsArgumentError);
      expect(() => new Int32(17) << null, throws);
    });

    test(">>", () {
      expect(new Int32(0x12345678) >> 7, new Int32(0x12345678 >> 7));
      expect(() => new Int32(17) >> -1, throwsArgumentError);
      expect(() => new Int32(17) >> null, throws);
    });

    test("shiftRightUnsigned", () {
      expect(new Int32(0x12345678).shiftRightUnsigned(7),
          new Int32(0x12345678 >> 7));
      expect(() => (new Int32(17).shiftRightUnsigned(-1)), throwsArgumentError);
      expect(() => (new Int32(17).shiftRightUnsigned(null)), throws);
    });
  });

  group("conversions", () {
    test("toSigned", () {
      expect(Int32.ONE.toSigned(2), Int32.ONE);
      expect(Int32.ONE.toSigned(1), -Int32.ONE);
      expect(Int32.MAX_VALUE.toSigned(32), Int32.MAX_VALUE);
      expect(Int32.MIN_VALUE.toSigned(32), Int32.MIN_VALUE);
      expect(Int32.MAX_VALUE.toSigned(31), -Int32.ONE);
      expect(Int32.MIN_VALUE.toSigned(31), Int32.ZERO);
      expect(() => Int32.ONE.toSigned(0), throws);
      expect(() => Int32.ONE.toSigned(33), throws);
    });
    test("toUnsigned", () {
      expect(Int32.ONE.toUnsigned(1), Int32.ONE);
      expect(Int32.ONE.toUnsigned(0), Int32.ZERO);
      expect(Int32.MAX_VALUE.toUnsigned(32), Int32.MAX_VALUE);
      expect(Int32.MIN_VALUE.toUnsigned(32), Int32.MIN_VALUE);
      expect(Int32.MAX_VALUE.toUnsigned(31), Int32.MAX_VALUE);
      expect(Int32.MIN_VALUE.toUnsigned(31), Int32.ZERO);
      expect(() => Int32.ONE.toUnsigned(-1), throws);
      expect(() => Int32.ONE.toUnsigned(33), throws);
    });
    test("toDouble", () {
      expect(new Int32(17).toDouble(), same(17.0));
      expect(new Int32(-17).toDouble(), same(-17.0));
    });
    test("toInt", () {
      expect(new Int32(17).toInt(), 17);
      expect(new Int32(-17).toInt(), -17);
    });
    test("toInt32", () {
      expect(new Int32(17).toInt32(), new Int32(17));
      expect(new Int32(-17).toInt32(), new Int32(-17));
    });
    test("toInt64", () {
      expect(new Int32(17).toInt64(), new Int64(17));
      expect(new Int32(-17).toInt64(), new Int64(-17));
    });
  });

  group("parse", () {
    test("base 10", () {
      checkInt(int x) {
        expect(Int32.parseRadix('$x', 10), new Int32(x));
      }
      checkInt(0);
      checkInt(1);
      checkInt(1000);
      checkInt(12345678);
      checkInt(2147483647);
      checkInt(2147483648);
      checkInt(4294967295);
      checkInt(4294967296);
      expect(() => Int32.parseRadix('xyzzy', -1), throwsArgumentError);
      expect(() => Int32.parseRadix('plugh', 10),
          throwsA(new isInstanceOf<FormatException>()));
    });

    test("parseRadix", () {
      check(String s, int r, String x) {
        expect(Int32.parseRadix(s, r).toString(), x);
      }
      check('deadbeef', 16, '-559038737');
      check('95', 12, '113');
    });
  });

  group("string representation", () {
    test("toString", () {
      expect(new Int32(0).toString(), "0");
      expect(new Int32(1).toString(), "1");
      expect(new Int32(-1).toString(), "-1");
      expect(new Int32(1000).toString(), "1000");
      expect(new Int32(-1000).toString(), "-1000");
      expect(new Int32(123456789).toString(), "123456789");
      expect(new Int32(2147483647).toString(), "2147483647");
      expect(new Int32(2147483648).toString(), "-2147483648");
      expect(new Int32(2147483649).toString(), "-2147483647");
      expect(new Int32(2147483650).toString(), "-2147483646");
      expect(new Int32(-2147483648).toString(), "-2147483648");
      expect(new Int32(-2147483649).toString(), "2147483647");
      expect(new Int32(-2147483650).toString(), "2147483646");
    });
  });

  group("toHexString", () {
    test("returns hexadecimal string representation", () {
      expect(new Int32(-1).toHexString(), "-1");
      expect((new Int32(-1) >> 8).toHexString(), "-1");
      expect((new Int32(-1) << 8).toHexString(), "-100");
      expect(new Int32(123456789).toHexString(), "75bcd15");
      expect(new Int32(-1).shiftRightUnsigned(8).toHexString(), "ffffff");
    });
  });

  group("toRadixString", () {
    test("returns base n string representation", () {
      expect(new Int32(123456789).toRadixString(5), "223101104124");
    });
  });
}
