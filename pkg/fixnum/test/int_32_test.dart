// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library int32test;
import 'package:fixnum/fixnum.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("arithmetic operators", () {
    int32 n1 = new int32.fromInt(1234);
    int32 n2 = new int32.fromInt(9876);
    int32 n3 = new int32.fromInt(-1234);
    int32 n4 = new int32.fromInt(-9876);
    int32 n5 = new int32.fromInt(0x12345678);
    int32 n6 = new int32.fromInt(0x22222222);

    test("+", () {
      expect(n1 + n2, new int32.fromInt(11110));
      expect(n3 + n2, new int32.fromInt(8642));
      expect(n3 + n4, new int32.fromInt(-11110));
      expect(int32.MAX_VALUE + 1, int32.MIN_VALUE);
      expect(() => new int32.fromInt(17) + null, throws);
    });

    test("-", () {
      expect(n1 - n2, new int32.fromInt(-8642));
      expect(n3 - n2, new int32.fromInt(-11110));
      expect(n3 - n4, new int32.fromInt(8642));
      expect(int32.MIN_VALUE - 1, int32.MAX_VALUE);
      expect(() => new int32.fromInt(17) - null, throws);
    });

    test("unary -", () {
      expect(-n1, new int32.fromInt(-1234));
      expect(-int32.ZERO, int32.ZERO);
    });

    test("*", () {
      expect(n1 * n2, new int32.fromInt(12186984));
      expect(n2 * n3, new int32.fromInt(-12186984));
      expect(n3 * n3, new int32.fromInt(1522756));
      expect(n3 * n2, new int32.fromInt(-12186984));
      expect(new int32.fromInt(0x12345678) * new int32.fromInt(0x22222222),
          new int32.fromInt(-899716112));
      expect((new int32.fromInt(123456789) * new int32.fromInt(987654321)),
          new int32.fromInt(-67153019));
      expect(new int32.fromInt(0x12345678) * new int64.fromInt(0x22222222),
          new int64.fromInts(0x026D60DC, 0xCA5F6BF0));
      expect((new int32.fromInt(123456789) * 987654321),
          new int32.fromInt(-67153019));
      expect(() => new int32.fromInt(17) * null, throws);
    });

    test("~/", () {
      expect(new int32.fromInt(829893893) ~/ new int32.fromInt(1919),
          new int32.fromInt(432461));
      expect(new int32.fromInt(0x12345678) ~/ new int32.fromInt(0x22),
          new int32.fromInt(0x12345678 ~/ 0x22));
      expect(new int32.fromInt(829893893) ~/ new int64.fromInt(1919),
          new int32.fromInt(432461));
      expect(new int32.fromInt(0x12345678) ~/ new int64.fromInt(0x22),
          new int32.fromInt(0x12345678 ~/ 0x22));
      expect(new int32.fromInt(829893893) ~/ 1919, new int32.fromInt(432461));
      expect(() => new int32.fromInt(17) ~/ int32.ZERO, throws);
      expect(() => new int32.fromInt(17) ~/ null, throws);
    });

    test("%", () {
      expect(new int32.fromInt(0x12345678) % new int32.fromInt(0x22),
          new int32.fromInt(0x12345678 % 0x22));
      expect(new int32.fromInt(0x12345678) % new int64.fromInt(0x22),
          new int32.fromInt(0x12345678 % 0x22));
      expect(() => new int32.fromInt(17) % null, throws);
    });

    test("remainder", () {
      expect(new int32.fromInt(0x12345678).remainder(new int32.fromInt(0x22)),
          new int32.fromInt(0x12345678.remainder(0x22)));
      expect(new int32.fromInt(0x12345678).remainder(new int32.fromInt(-0x22)),
          new int32.fromInt(0x12345678.remainder(-0x22)));
      expect(new int32.fromInt(-0x12345678).remainder(new int32.fromInt(-0x22)),
          new int32.fromInt(-0x12345678.remainder(-0x22)));
      expect(new int32.fromInt(-0x12345678).remainder(new int32.fromInt(0x22)),
          new int32.fromInt(-0x12345678.remainder(0x22)));
      expect(new int32.fromInt(0x12345678).remainder(new int64.fromInt(0x22)),
          new int32.fromInt(0x12345678.remainder(0x22)));
      expect(() => new int32.fromInt(17).remainder(null), throws);
    });
  });

  group("comparison operators", () {
    test("<", () {
      expect(new int32.fromInt(17) < new int32.fromInt(18), true);
      expect(new int32.fromInt(17) < new int32.fromInt(17), false);
      expect(new int32.fromInt(17) < new int32.fromInt(16), false);
      expect(int32.MIN_VALUE < int32.MAX_VALUE, true);
      expect(int32.MAX_VALUE < int32.MIN_VALUE, false);
      expect(() => new int32.fromInt(17) < null, throws);
    });

    test("<=", () {
      expect(new int32.fromInt(17) <= new int32.fromInt(18), true);
      expect(new int32.fromInt(17) <= new int32.fromInt(17), true);
      expect(new int32.fromInt(17) <= new int32.fromInt(16), false);
      expect(int32.MIN_VALUE <= int32.MAX_VALUE, true);
      expect(int32.MAX_VALUE <= int32.MIN_VALUE, false);
      expect(() => new int32.fromInt(17) <= null, throws);
    });

    test("==", () {
      expect(new int32.fromInt(17) == new int32.fromInt(18), false);
      expect(new int32.fromInt(17) == new int32.fromInt(17), true);
      expect(new int32.fromInt(17) == new int32.fromInt(16), false);
      expect(int32.MIN_VALUE == int32.MAX_VALUE, false);
      expect(new int32.fromInt(17) == null, false);
    });

    test(">=", () {
      expect(new int32.fromInt(17) >= new int32.fromInt(18), false);
      expect(new int32.fromInt(17) >= new int32.fromInt(17), true);
      expect(new int32.fromInt(17) >= new int32.fromInt(16), true);
      expect(int32.MIN_VALUE >= int32.MAX_VALUE, false);
      expect(int32.MAX_VALUE >= int32.MIN_VALUE, true);
      expect(() => new int32.fromInt(17) >= null, throws);
    });

    test(">", () {
      expect(new int32.fromInt(17) > new int32.fromInt(18), false);
      expect(new int32.fromInt(17) > new int32.fromInt(17), false);
      expect(new int32.fromInt(17) > new int32.fromInt(16), true);
      expect(int32.MIN_VALUE > int32.MAX_VALUE, false);
      expect(int32.MAX_VALUE > int32.MIN_VALUE, true);
      expect(() => new int32.fromInt(17) > null, throws);
    });
  });

  group("bitwise operators", () {
    test("&", () {
      expect(new int32.fromInt(0x12345678) & new int32.fromInt(0x22222222),
          new int32.fromInt(0x12345678 & 0x22222222));
      expect(new int32.fromInt(0x12345678) & new int64.fromInt(0x22222222),
          new int64.fromInt(0x12345678 & 0x22222222));
      expect(() => new int32.fromInt(17) & null, throwsArgumentError);
    });

    test("|", () {
      expect(new int32.fromInt(0x12345678) | new int32.fromInt(0x22222222),
          new int32.fromInt(0x12345678 | 0x22222222));
      expect(new int32.fromInt(0x12345678) | new int64.fromInt(0x22222222),
          new int64.fromInt(0x12345678 | 0x22222222));
      expect(() => new int32.fromInt(17) | null, throws);
    });

    test("^", () {
      expect(new int32.fromInt(0x12345678) ^ new int32.fromInt(0x22222222),
          new int32.fromInt(0x12345678 ^ 0x22222222));
      expect(new int32.fromInt(0x12345678) ^ new int64.fromInt(0x22222222),
          new int64.fromInt(0x12345678 ^ 0x22222222));
      expect(() => new int32.fromInt(17) ^ null, throws);
    });

    test("~", () {
      expect(~(new int32.fromInt(0x12345678)), new int32.fromInt(~0x12345678));
      expect(-(new int32.fromInt(0x12345678)), new int64.fromInt(-0x12345678));
    });
  });

  group("bitshift operators", () {
    test("<<", () {
      expect(new int32.fromInt(0x12345678) << 7,
          new int32.fromInt(0x12345678 << 7));
      expect(() => new int32.fromInt(17) << -1, throwsArgumentError);
      expect(() => new int32.fromInt(17) << null, throws);
    });

    test(">>", () {
      expect(new int32.fromInt(0x12345678) >> 7,
          new int32.fromInt(0x12345678 >> 7));
      expect(() => new int32.fromInt(17) >> -1, throwsArgumentError);
      expect(() => new int32.fromInt(17) >> null, throws);
    });

    test("shiftRightUnsigned", () {
      expect(new int32.fromInt(0x12345678).shiftRightUnsigned(7),
          new int32.fromInt(0x12345678 >> 7));
      expect(() => (new int32.fromInt(17).shiftRightUnsigned(-1)),
          throwsArgumentError);
      expect(() => (new int32.fromInt(17).shiftRightUnsigned(null)), throws);
    });
  });

  group("type conversions", () {
    expect(new int32.fromInt(17).toInt(), 17);
    expect(new int32.fromInt(-17).toInt(), -17);
    expect(new int32.fromInt(17).toInt32(), new int32.fromInt(17));
    expect(new int32.fromInt(-17).toInt32(), new int32.fromInt(-17));
    expect(new int32.fromInt(17).toInt64(), new int64.fromInt(17));
    expect(new int32.fromInt(-17).toInt64(), new int64.fromInt(-17));
  });

  group("string representation", () {
    test("toString", () {
      expect(new int32.fromInt(0).toString(), "0");
      expect(new int32.fromInt(1).toString(), "1");
      expect(new int32.fromInt(-1).toString(), "-1");
      expect(new int32.fromInt(1000).toString(), "1000");
      expect(new int32.fromInt(-1000).toString(), "-1000");
      expect(new int32.fromInt(123456789).toString(), "123456789");
      expect(new int32.fromInt(2147483647).toString(), "2147483647");
      expect(new int32.fromInt(2147483648).toString(), "-2147483648");
      expect(new int32.fromInt(2147483649).toString(), "-2147483647");
      expect(new int32.fromInt(2147483650).toString(), "-2147483646");
      expect(new int32.fromInt(-2147483648).toString(), "-2147483648");
      expect(new int32.fromInt(-2147483649).toString(), "2147483647");
      expect(new int32.fromInt(-2147483650).toString(), "2147483646");
    });
  });

  group("toHexString", () {
    test("returns hexadecimal string representation", () {
      expect(new int32.fromInt(-1).toHexString(), "-1");
      expect((new int32.fromInt(-1) >> 8).toHexString(), "-1");
      expect((new int32.fromInt(-1) << 8).toHexString(), "-100");
      expect(new int32.fromInt(123456789).toHexString(), "75bcd15");
      expect(new int32.fromInt(-1).shiftRightUnsigned(8).toHexString(),
          "ffffff");
    });
  });

  group("toRadixString", () {
    test("returns base n string representation", () {
      expect(new int32.fromInt(123456789).toRadixString(5), "223101104124");
    });
  });
}
