// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library int64test;
import 'package:fixnum/fixnum.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("is-tests", () {
    test("isEven", () {
      expect((-Int64.ONE).isEven, false);
      expect(Int64.ZERO.isEven, true);
      expect(Int64.ONE.isEven, false);
      expect(Int64.TWO.isEven, true);
    });
    test("isMaxValue", () {
      expect(Int64.MIN_VALUE.isMaxValue, false);
      expect(Int64.ZERO.isMaxValue, false);
      expect(Int64.MAX_VALUE.isMaxValue, true);
    });
    test("isMinValue", () {
      expect(Int64.MIN_VALUE.isMinValue, true);
      expect(Int64.ZERO.isMinValue, false);
      expect(Int64.MAX_VALUE.isMinValue, false);
    });
    test("isNegative", () {
      expect(Int64.MIN_VALUE.isNegative, true);
      expect(Int64.ZERO.isNegative, false);
      expect(Int64.ONE.isNegative, false);
    });
    test("isOdd", () {
      expect((-Int64.ONE).isOdd, true);
      expect(Int64.ZERO.isOdd, false);
      expect(Int64.ONE.isOdd, true);
      expect(Int64.TWO.isOdd, false);
    });
    test("isZero", () {
      expect(Int64.MIN_VALUE.isZero, false);
      expect(Int64.ZERO.isZero, true);
      expect(Int64.MAX_VALUE.isZero, false);
    });
    test("bitLength", () {
      expect(new Int64(-2).bitLength, 1);
      expect((-Int64.ONE).bitLength, 0);
      expect(Int64.ZERO.bitLength, 0);
      expect((Int64.ONE << 21).bitLength, 22);
      expect((Int64.ONE << 22).bitLength, 23);
      expect((Int64.ONE << 43).bitLength, 44);
      expect((Int64.ONE << 44).bitLength, 45);
      expect(new Int64(2).bitLength, 2);
      expect(Int64.MAX_VALUE.bitLength, 63);
      expect(Int64.MIN_VALUE.bitLength, 63);
    });
  });

  group("arithmetic operators", () {
    Int64 n1 = new Int64(1234);
    Int64 n2 = new Int64(9876);
    Int64 n3 = new Int64(-1234);
    Int64 n4 = new Int64(-9876);
    Int64 n5 = new Int64.fromInts(0x12345678, 0xabcdabcd);
    Int64 n6 = new Int64.fromInts(0x77773333, 0x22224444);

    test("+", () {
      expect(n1 + n2, new Int64(11110));
      expect(n3 + n2, new Int64(8642));
      expect(n3 + n4, new Int64(-11110));
      expect(n5 + n6, new Int64.fromInts(0x89ab89ab, 0xcdeff011));
      expect(Int64.MAX_VALUE + 1, Int64.MIN_VALUE);
    });

    test("-", () {
      expect(n1 - n2, new Int64(-8642));
      expect(n3 - n2, new Int64(-11110));
      expect(n3 - n4, new Int64(8642));
      expect(n5 - n6, new Int64.fromInts(0x9abd2345, 0x89ab6789));
      expect(Int64.MIN_VALUE - 1, Int64.MAX_VALUE);
    });

    test("unary -", () {
      expect(-n1, new Int64(-1234));
      expect(-Int64.ZERO, Int64.ZERO);
    });

    test("*", () {
      expect(new Int64(1111) * new Int64(3), new Int64(3333));
      expect(new Int64(1111) * new Int64(-3), new Int64(-3333));
      expect(new Int64(-1111) * new Int64(3), new Int64(-3333));
      expect(new Int64(-1111) * new Int64(-3), new Int64(3333));
      expect(new Int64(100) * Int64.ZERO, Int64.ZERO);

      expect(new Int64.fromInts(0x12345678, 0x12345678) *
          new Int64.fromInts(0x1234, 0x12345678),
          new Int64.fromInts(0x7ff63f7c, 0x1df4d840));
      expect(new Int64.fromInts(0xf2345678, 0x12345678) *
          new Int64.fromInts(0x1234, 0x12345678),
          new Int64.fromInts(0x7ff63f7c, 0x1df4d840));
      expect(new Int64.fromInts(0xf2345678, 0x12345678) *
          new Int64.fromInts(0xffff1234, 0x12345678),
          new Int64.fromInts(0x297e3f7c, 0x1df4d840));

      // RHS Int32
      expect((new Int64(123456789) * new Int32(987654321)),
          new Int64.fromInts(0x1b13114, 0xfbff5385));
      expect((new Int64(123456789) * new Int32(987654321)),
          new Int64.fromInts(0x1b13114, 0xfbff5385));

      // Wraparound
      expect((new Int64(123456789) * new Int64(987654321)),
          new Int64.fromInts(0x1b13114, 0xfbff5385));

      expect(Int64.MIN_VALUE * new Int64(2), Int64.ZERO);
      expect(Int64.MIN_VALUE * new Int64(1), Int64.MIN_VALUE);
      expect(Int64.MIN_VALUE * new Int64(-1), Int64.MIN_VALUE);
    });

    test("~/", () {
      Int64 deadBeef = new Int64.fromInts(0xDEADBEEF, 0xDEADBEEF);
      Int64 ten = new Int64(10);

      expect(deadBeef ~/ ten, new Int64.fromInts(0xfcaaf97e, 0x63115fe5));
      expect(Int64.ONE ~/ Int64.TWO, Int64.ZERO);
      expect(Int64.MAX_VALUE ~/ Int64.TWO,
          new Int64.fromInts(0x3fffffff, 0xffffffff));
      expect(Int64.ZERO ~/ new Int64(1000), Int64.ZERO);
      expect(Int64.MIN_VALUE ~/ Int64.MIN_VALUE, Int64.ONE);
      expect(new Int64(1000) ~/ Int64.MIN_VALUE, Int64.ZERO);
      expect(Int64.MIN_VALUE ~/ new Int64(8192), new Int64(-1125899906842624));
      expect(Int64.MIN_VALUE ~/ new Int64(8193), new Int64(-1125762484664320));
      expect(new Int64(-1000) ~/ new Int64(8192), Int64.ZERO);
      expect(new Int64(-1000) ~/ new Int64(8193), Int64.ZERO);
      expect(new Int64(-1000000000) ~/ new Int64(8192), new Int64(-122070));
      expect(new Int64(-1000000000) ~/ new Int64(8193), new Int64(-122055));
      expect(new Int64(1000000000) ~/ new Int64(8192), new Int64(122070));
      expect(new Int64(1000000000) ~/ new Int64(8193), new Int64(122055));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000000, 0x00000400),
          new Int64.fromInts(0x1fffff, 0xffffffff));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000000, 0x00040000),
          new Int64.fromInts(0x1fff, 0xffffffff));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000000, 0x04000000),
          new Int64.fromInts(0x1f, 0xffffffff));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000004, 0x00000000),
          new Int64(536870911));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000400, 0x00000000),
          new Int64(2097151));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00040000, 0x00000000),
          new Int64(8191));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x04000000, 0x00000000),
          new Int64(31));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000000, 0x00000300),
          new Int64.fromInts(0x2AAAAA, 0xAAAAAAAA));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00000000, 0x30000000),
          new Int64.fromInts(0x2, 0xAAAAAAAA));
      expect(Int64.MAX_VALUE ~/ new Int64.fromInts(0x00300000, 0x00000000),
          new Int64(0x2AA));
      expect(Int64.MAX_VALUE ~/ new Int64(0x123456),
          new Int64.fromInts(0x708, 0x002E9501));
      expect(Int64.MAX_VALUE % new Int64(0x123456), new Int64(0x3BDA9));
      expect(new Int64(5) ~/ new Int64(5), Int64.ONE);
      expect(new Int64(1000) ~/ new Int64(3), new Int64(333));
      expect(new Int64(1000) ~/ new Int64(-3), new Int64(-333));
      expect(new Int64(-1000) ~/ new Int64(3), new Int64(-333));
      expect(new Int64(-1000) ~/ new Int64(-3), new Int64(333));
      expect(new Int64(3) ~/ new Int64(1000), Int64.ZERO);
      expect(new Int64.fromInts( 0x12345678, 0x12345678) ~/
          new Int64.fromInts(0x0, 0x123),
          new Int64.fromInts(0x1003d0, 0xe84f5ae8));
      expect(new Int64.fromInts(0x12345678, 0x12345678) ~/
          new Int64.fromInts(0x1234, 0x12345678),
          new Int64.fromInts(0x0, 0x10003));
      expect(new Int64.fromInts(0xf2345678, 0x12345678) ~/
          new Int64.fromInts(0x1234, 0x12345678),
          new Int64.fromInts(0xffffffff, 0xffff3dfe));
      expect(new Int64.fromInts(0xf2345678, 0x12345678) ~/
          new Int64.fromInts(0xffff1234, 0x12345678),
          new Int64.fromInts(0x0, 0xeda));
      expect(new Int64(829893893) ~/ new Int32(1919), new Int32(432461));
      expect(new Int64(829893893) ~/ new Int64(1919), new Int32(432461));
      expect(new Int64(829893893) ~/ 1919, new Int32(432461));
      expect(() => new Int64(1) ~/ Int64.ZERO,
          throwsA(new isInstanceOf<IntegerDivisionByZeroException>()));
      expect(Int64.MIN_VALUE ~/ new Int64(2),
          new Int64.fromInts(0xc0000000, 0x00000000));
      expect(Int64.MIN_VALUE ~/ new Int64(1), Int64.MIN_VALUE);
      expect(Int64.MIN_VALUE ~/ new Int64(-1), Int64.MIN_VALUE);
      expect(() => new Int64(17) ~/ Int64.ZERO, throws);
      expect(() => new Int64(17) ~/ null, throwsArgumentError);
    });

    test("%", () {
      // Define % as Euclidean mod, with positive result for all arguments
      expect(Int64.ZERO % new Int64(1000), Int64.ZERO);
      expect(Int64.MIN_VALUE % Int64.MIN_VALUE, Int64.ZERO);
      expect(new Int64(1000) % Int64.MIN_VALUE, new Int64(1000));
      expect(Int64.MIN_VALUE % new Int64(8192), Int64.ZERO);
      expect(Int64.MIN_VALUE % new Int64(8193), new Int64(6145));
      expect(new Int64(-1000) % new Int64(8192), new Int64(7192));
      expect(new Int64(-1000) % new Int64(8193), new Int64(7193));
      expect(new Int64(-1000000000) % new Int64(8192), new Int64(5632));
      expect(new Int64(-1000000000) % new Int64(8193), new Int64(4808));
      expect(new Int64(1000000000) % new Int64(8192), new Int64(2560));
      expect(new Int64(1000000000) % new Int64(8193), new Int64(3385));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x00000000, 0x00000400),
          new Int64.fromInts(0x0, 0x3ff));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x00000000, 0x00040000),
          new Int64.fromInts(0x0, 0x3ffff));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x00000000, 0x04000000),
          new Int64.fromInts(0x0, 0x3ffffff));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x00000004, 0x00000000),
          new Int64.fromInts(0x3, 0xffffffff));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x00000400, 0x00000000),
          new Int64.fromInts(0x3ff, 0xffffffff));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x00040000, 0x00000000),
          new Int64.fromInts(0x3ffff, 0xffffffff));
      expect(Int64.MAX_VALUE % new Int64.fromInts(0x04000000, 0x00000000),
          new Int64.fromInts(0x3ffffff, 0xffffffff));
      expect(new Int64(0x12345678).remainder(new Int64(0x22)),
          new Int64(0x12345678.remainder(0x22)));
      expect(new Int64(0x12345678).remainder(new Int64(-0x22)),
          new Int64(0x12345678.remainder(-0x22)));
      expect(new Int64(-0x12345678).remainder(new Int64(-0x22)),
          new Int64(-0x12345678.remainder(-0x22)));
      expect(new Int64(-0x12345678).remainder(new Int64(0x22)),
          new Int64(-0x12345678.remainder(0x22)));
      expect(new Int32(0x12345678).remainder(new Int64(0x22)),
          new Int64(0x12345678.remainder(0x22)));
    });

    test("clamp", () {
      Int64 val = new Int64(17);
      expect(val.clamp(20, 30), new Int64(20));
      expect(val.clamp(10, 20), new Int64(17));
      expect(val.clamp(10, 15), new Int64(15));

      expect(val.clamp(new Int32(20), new Int32(30)), new Int64(20));
      expect(val.clamp(new Int32(10), new Int32(20)), new Int64(17));
      expect(val.clamp(new Int32(10), new Int32(15)), new Int64(15));

      expect(val.clamp(new Int64(20), new Int64(30)), new Int64(20));
      expect(val.clamp(new Int64(10), new Int64(20)), new Int64(17));
      expect(val.clamp(new Int64(10), new Int64(15)), new Int64(15));
      expect(val.clamp(Int64.MIN_VALUE, new Int64(30)), new Int64(17));
      expect(val.clamp(new Int64(10), Int64.MAX_VALUE), new Int64(17));

      expect(() => val.clamp(1, 'b'), throwsA(isArgumentError));
      expect(() => val.clamp('a', 1), throwsA(isArgumentError));
    });
  });

  group("comparison operators", () {
    Int64 largeNeg = new Int64.fromInts(0x82341234, 0x0);
    Int64 largePos = new Int64.fromInts(0x12341234, 0x0);
    Int64 largePosPlusOne = largePos + new Int64(1);

    test("<", () {
      expect(new Int64(10) < new Int64(11), true);
      expect(new Int64(10) < new Int64(10), false);
      expect(new Int64(10) < new Int64(9), false);
      expect(new Int64(10) < new Int32(11), true);
      expect(new Int64(10) < new Int32(10), false);
      expect(new Int64(10) < new Int32(9), false);
      expect(new Int64(-10) < new Int64(-11), false);
      expect(Int64.MIN_VALUE < Int64.ZERO, true);
      expect(largeNeg < largePos, true);
      expect(largePos < largePosPlusOne, true);
      expect(largePos < largePos, false);
      expect(largePosPlusOne < largePos, false);
      expect(Int64.MIN_VALUE < Int64.MAX_VALUE, true);
      expect(Int64.MAX_VALUE < Int64.MIN_VALUE, false);
      expect(() => new Int64(17) < null, throwsArgumentError);
    });

    test("<=", () {
      expect(new Int64(10) <= new Int64(11), true);
      expect(new Int64(10) <= new Int64(10), true);
      expect(new Int64(10) <= new Int64(9), false);
      expect(new Int64(10) <= new Int32(11), true);
      expect(new Int64(10) <= new Int32(10), true);
      expect(new Int64(10) <= new Int64(9), false);
      expect(new Int64(-10) <= new Int64(-11), false);
      expect(new Int64(-10) <= new Int64(-10), true);
      expect(largeNeg <= largePos, true);
      expect(largePos <= largeNeg, false);
      expect(largePos <= largePosPlusOne, true);
      expect(largePos <= largePos, true);
      expect(largePosPlusOne <= largePos, false);
      expect(Int64.MIN_VALUE <= Int64.MAX_VALUE, true);
      expect(Int64.MAX_VALUE <= Int64.MIN_VALUE, false);
      expect(() => new Int64(17) <= null, throwsArgumentError);
    });

    test("==", () {
      expect(new Int64(10) == new Int64(11), false);
      expect(new Int64(10) == new Int64(10), true);
      expect(new Int64(10) == new Int64(9), false);
      expect(new Int64(10) == new Int32(11), false);
      expect(new Int64(10) == new Int32(10), true);
      expect(new Int64(10) == new Int32(9), false);
      expect(new Int64(-10) == new Int64(-10), true);
      expect(new Int64(-10) != new Int64(-10), false);
      expect(largePos == largePos, true);
      expect(largePos == largePosPlusOne, false);
      expect(largePosPlusOne == largePos, false);
      expect(Int64.MIN_VALUE == Int64.MAX_VALUE, false);
      expect(new Int64(17) == new Object(), false);
      expect(new Int64(17) == null, false);
    });

    test(">=", () {
      expect(new Int64(10) >= new Int64(11), false);
      expect(new Int64(10) >= new Int64(10), true);
      expect(new Int64(10) >= new Int64(9), true);
      expect(new Int64(10) >= new Int32(11), false);
      expect(new Int64(10) >= new Int32(10), true);
      expect(new Int64(10) >= new Int32(9), true);
      expect(new Int64(-10) >= new Int64(-11), true);
      expect(new Int64(-10) >= new Int64(-10), true);
      expect(largePos >= largeNeg, true);
      expect(largeNeg >= largePos, false);
      expect(largePos >= largePosPlusOne, false);
      expect(largePos >= largePos, true);
      expect(largePosPlusOne >= largePos, true);
      expect(Int64.MIN_VALUE >= Int64.MAX_VALUE, false);
      expect(Int64.MAX_VALUE >= Int64.MIN_VALUE, true);
      expect(() => new Int64(17) >= null, throwsArgumentError);
    });

    test(">", () {
      expect(new Int64(10) > new Int64(11), false);
      expect(new Int64(10) > new Int64(10), false);
      expect(new Int64(10) > new Int64(9), true);
      expect(new Int64(10) > new Int32(11), false);
      expect(new Int64(10) > new Int32(10), false);
      expect(new Int64(10) > new Int32(9), true);
      expect(new Int64(-10) > new Int64(-11), true);
      expect(new Int64(10) > new Int64(-11), true);
      expect(new Int64(-10) > new Int64(11), false);
      expect(largePos > largeNeg, true);
      expect(largeNeg > largePos, false);
      expect(largePos > largePosPlusOne, false);
      expect(largePos > largePos, false);
      expect(largePosPlusOne > largePos, true);
      expect(Int64.ZERO > Int64.MIN_VALUE, true);
      expect(Int64.MIN_VALUE > Int64.MAX_VALUE, false);
      expect(Int64.MAX_VALUE > Int64.MIN_VALUE, true);
      expect(() => new Int64(17) > null, throwsArgumentError);
    });
  });

  group("bitwise operators", () {
    Int64 n1 = new Int64(1234);
    Int64 n2 = new Int64(9876);
    Int64 n3 = new Int64(-1234);
    Int64 n4 = new Int64(0x1234) << 32;
    Int64 n5 = new Int64(0x9876) << 32;

    test("&", () {
      expect(n1 & n2, new Int64(1168));
      expect(n3 & n2, new Int64(8708));
      expect(n4 & n5, new Int64(0x1034) << 32);
      expect(() => n1 & null, throwsArgumentError);
    });

    test("|", () {
      expect(n1 | n2, new Int64(9942));
      expect(n3 | n2, new Int64(-66));
      expect(n4 | n5, new Int64(0x9a76) << 32);
      expect(() => n1 | null, throwsArgumentError);
    });

    test("^", () {
      expect(n1 ^ n2, new Int64(8774));
      expect(n3 ^ n2, new Int64(-8774));
      expect(n4 ^ n5, new Int64(0x8a42) << 32);
      expect(() => n1 ^ null, throwsArgumentError);
    });

    test("~", () {
      expect(-new Int64(1), new Int64(-1));
      expect(-new Int64(-1), new Int64(1));
      expect(-Int64.MIN_VALUE, Int64.MIN_VALUE);

      expect(~n1, new Int64(-1235));
      expect(~n2, new Int64(-9877));
      expect(~n3, new Int64(1233));
      expect(~n4, new Int64.fromInts(0xffffedcb, 0xffffffff));
      expect(~n5, new Int64.fromInts(0xffff6789, 0xffffffff));
    });
  });

  group("bitshift operators", () {
    test("<<", () {
      expect(new Int64.fromInts(0x12341234, 0x45674567) << 10,
          new Int64.fromInts(0xd048d115, 0x9d159c00));
      expect(new Int64.fromInts(0x92341234, 0x45674567) << 10,
          new Int64.fromInts(0xd048d115, 0x9d159c00));
      expect(new Int64(-1) << 5, new Int64(-32));
      expect(new Int64(-1) << 0, new Int64(-1));
      expect(() => new Int64(17) << -1, throwsArgumentError);
      expect(() => new Int64(17) << null, throws);
    });

    test(">>", () {
      expect((Int64.MIN_VALUE >> 13).toString(), "-1125899906842624");
      expect(new Int64.fromInts(0x12341234, 0x45674567) >> 10,
          new Int64.fromInts(0x48d04, 0x8d1159d1));
      expect(new Int64.fromInts(0x92341234, 0x45674567) >> 10,
          new Int64.fromInts(0xffe48d04, 0x8d1159d1));
      expect(new Int64.fromInts(0xFFFFFFF, 0xFFFFFFFF) >> 34,
          new Int64(67108863));
      for (int n = 0; n <= 66; n++) {
        expect(new Int64(-1) >> n, new Int64(-1));
      }
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 8,
          new Int64.fromInts(0x00723456, 0x789abcde));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 16,
          new Int64.fromInts(0x00007234, 0x56789abc));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 24,
          new Int64.fromInts(0x00000072, 0x3456789a));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 28,
          new Int64.fromInts(0x00000007, 0x23456789));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 32,
          new Int64.fromInts(0x00000000, 0x72345678));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 36,
          new Int64.fromInts(0x00000000, 0x07234567));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 40,
          new Int64.fromInts(0x00000000, 0x00723456));
      expect(new Int64.fromInts(0x72345678, 0x9abcde00) >> 44,
          new Int64.fromInts(0x00000000, 0x00072345));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0) >> 48,
          new Int64.fromInts(0x00000000, 0x00007234));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 8,
          new Int64.fromInts(0xff923456, 0x789abcde));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 16,
          new Int64.fromInts(0xffff9234, 0x56789abc));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 24,
          new Int64.fromInts(0xffffff92, 0x3456789a));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 28,
          new Int64.fromInts(0xfffffff9, 0x23456789));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 32,
          new Int64.fromInts(0xffffffff, 0x92345678));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 36,
          new Int64.fromInts(0xffffffff, 0xf9234567));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 40,
          new Int64.fromInts(0xffffffff, 0xff923456));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 44,
          new Int64.fromInts(0xffffffff, 0xfff92345));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0) >> 48,
          new Int64.fromInts(0xffffffff, 0xffff9234));
      expect(() => new Int64(17) >> -1, throwsArgumentError);
      expect(() => new Int64(17) >> null, throws);
    });

    test("shiftRightUnsigned", () {
      expect(new Int64.fromInts(0x12341234, 0x45674567).shiftRightUnsigned(10),
          new Int64.fromInts(0x48d04, 0x8d1159d1));
      expect(new Int64.fromInts(0x92341234, 0x45674567).shiftRightUnsigned(10),
          new Int64.fromInts(0x248d04, 0x8d1159d1));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(8),
          new Int64.fromInts(0x00723456, 0x789abcde));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(16),
          new Int64.fromInts(0x00007234, 0x56789abc));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(24),
          new Int64.fromInts(0x00000072, 0x3456789a));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(28),
          new Int64.fromInts(0x00000007, 0x23456789));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(32),
          new Int64.fromInts(0x00000000, 0x72345678));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(36),
          new Int64.fromInts(0x00000000, 0x07234567));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(40),
          new Int64.fromInts(0x00000000, 0x00723456));
      expect(new Int64.fromInts(0x72345678, 0x9abcde00).shiftRightUnsigned(44),
          new Int64.fromInts(0x00000000, 0x00072345));
      expect(new Int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(48),
          new Int64.fromInts(0x00000000, 0x00007234));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(8),
          new Int64.fromInts(0x00923456, 0x789abcde));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(16),
          new Int64.fromInts(0x00009234, 0x56789abc));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(24),
          new Int64.fromInts(0x00000092, 0x3456789a));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(28),
          new Int64.fromInts(0x00000009, 0x23456789));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(32),
          new Int64.fromInts(0x00000000, 0x92345678));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(36),
          new Int64.fromInts(0x00000000, 0x09234567));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(40),
          new Int64.fromInts(0x00000000, 0x00923456));
      expect(new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(44),
          new Int64.fromInts(0x00000000, 0x00092345));
      expect(new Int64.fromInts(0x00000000, 0x00009234),
          new Int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(48));
      expect(() => new Int64(17).shiftRightUnsigned(-1),
          throwsArgumentError);
      expect(() => new Int64(17).shiftRightUnsigned(null), throws);
    });

    test("overflow", () {
      expect((new Int64(1) << 63) >> 1,
          -new Int64.fromInts(0x40000000, 0x00000000));
      expect((new Int64(-1) << 32) << 32, new Int64(0));
      expect(Int64.MIN_VALUE << 0, Int64.MIN_VALUE);
      expect(Int64.MIN_VALUE << 1, new Int64(0));
      expect((-new Int64.fromInts(8, 0)) >> 1,
          new Int64.fromInts(0xfffffffc, 0x00000000));
      expect((-new Int64.fromInts(8, 0)).shiftRightUnsigned(1),
          new Int64.fromInts(0x7ffffffc, 0x0));
    });
  });

  group("conversions", () {
    test("toSigned", () {
      expect((Int64.ONE << 44).toSigned(46), Int64.ONE << 44);
      expect((Int64.ONE << 44).toSigned(45), -(Int64.ONE << 44));
      expect((Int64.ONE << 22).toSigned(24), Int64.ONE << 22);
      expect((Int64.ONE << 22).toSigned(23), -(Int64.ONE << 22));
      expect(Int64.ONE.toSigned(2), Int64.ONE);
      expect(Int64.ONE.toSigned(1), -Int64.ONE);
      expect(Int64.MAX_VALUE.toSigned(64), Int64.MAX_VALUE);
      expect(Int64.MIN_VALUE.toSigned(64), Int64.MIN_VALUE);
      expect(Int64.MAX_VALUE.toSigned(63), -Int64.ONE);
      expect(Int64.MIN_VALUE.toSigned(63), Int64.ZERO);
      expect(() => Int64.ONE.toSigned(0), throws);
      expect(() => Int64.ONE.toSigned(65), throws);
    });
    test("toUnsigned", () {
      expect((Int64.ONE << 44).toUnsigned(45), Int64.ONE << 44);
      expect((Int64.ONE << 44).toUnsigned(44), Int64.ZERO);
      expect((Int64.ONE << 22).toUnsigned(23), Int64.ONE << 22);
      expect((Int64.ONE << 22).toUnsigned(22), Int64.ZERO);
      expect(Int64.ONE.toUnsigned(1), Int64.ONE);
      expect(Int64.ONE.toUnsigned(0), Int64.ZERO);
      expect(Int64.MAX_VALUE.toUnsigned(64), Int64.MAX_VALUE);
      expect(Int64.MIN_VALUE.toUnsigned(64), Int64.MIN_VALUE);
      expect(Int64.MAX_VALUE.toUnsigned(63), Int64.MAX_VALUE);
      expect(Int64.MIN_VALUE.toUnsigned(63), Int64.ZERO);
      expect(() => Int64.ONE.toUnsigned(-1), throws);
      expect(() => Int64.ONE.toUnsigned(65), throws);
    });
    test("toDouble", () {
      expect(new Int64(0).toDouble(), same(0.0));
      expect(new Int64(100).toDouble(), same(100.0));
      expect(new Int64(-100).toDouble(), same(-100.0));
      expect(new Int64(2147483647).toDouble(), same(2147483647.0));
      expect(new Int64(2147483648).toDouble(), same(2147483648.0));
      expect(new Int64(-2147483647).toDouble(), same(-2147483647.0));
      expect(new Int64(-2147483648).toDouble(), same(-2147483648.0));
      expect(new Int64(4503599627370495).toDouble(), same(4503599627370495.0));
      expect(new Int64(4503599627370496).toDouble(), same(4503599627370496.0));
      expect(new Int64(-4503599627370495).toDouble(),
          same(-4503599627370495.0));
      expect(new Int64(-4503599627370496).toDouble(),
          same(-4503599627370496.0));
      expect(Int64.parseInt("-10000000000000000").toDouble().toStringAsFixed(1),
          "-10000000000000000.0");
      expect(Int64.parseInt("-10000000000000001").toDouble().toStringAsFixed(1),
          "-10000000000000000.0");
      expect(Int64.parseInt("-10000000000000002").toDouble().toStringAsFixed(1),
          "-10000000000000002.0");
      expect(Int64.parseInt("-10000000000000003").toDouble().toStringAsFixed(1),
          "-10000000000000004.0");
      expect(Int64.parseInt("-10000000000000004").toDouble().toStringAsFixed(1),
          "-10000000000000004.0");
      expect(Int64.parseInt("-10000000000000005").toDouble().toStringAsFixed(1),
          "-10000000000000004.0");
      expect(Int64.parseInt("-10000000000000006").toDouble().toStringAsFixed(1),
          "-10000000000000006.0");
      expect(Int64.parseInt("-10000000000000007").toDouble().toStringAsFixed(1),
          "-10000000000000008.0");
      expect(Int64.parseInt("-10000000000000008").toDouble().toStringAsFixed(1),
          "-10000000000000008.0");
    });

    test("toInt", () {
      expect(new Int64(0).toInt(), 0);
      expect(new Int64(100).toInt(), 100);
      expect(new Int64(-100).toInt(), -100);
      expect(new Int64(2147483647).toInt(), 2147483647);
      expect(new Int64(2147483648).toInt(), 2147483648);
      expect(new Int64(-2147483647).toInt(), -2147483647);
      expect(new Int64(-2147483648).toInt(), -2147483648);
      expect(new Int64(4503599627370495).toInt(), 4503599627370495);
      expect(new Int64(4503599627370496).toInt(), 4503599627370496);
      expect(new Int64(-4503599627370495).toInt(), -4503599627370495);
      expect(new Int64(-4503599627370496).toInt(), -4503599627370496);
      expect(Int64.parseInt("-10000000000000000").toInt(),
          same(-10000000000000000));
      expect(Int64.parseInt("-10000000000000001").toInt(),
          same(-10000000000000001));
      expect(Int64.parseInt("-10000000000000002").toInt(),
          same(-10000000000000002));
      expect(Int64.parseInt("-10000000000000003").toInt(),
          same(-10000000000000003));
      expect(Int64.parseInt("-10000000000000004").toInt(),
          same(-10000000000000004));
      expect(Int64.parseInt("-10000000000000005").toInt(),
          same(-10000000000000005));
      expect(Int64.parseInt("-10000000000000006").toInt(),
          same(-10000000000000006));
      expect(Int64.parseInt("-10000000000000007").toInt(),
          same(-10000000000000007));
      expect(Int64.parseInt("-10000000000000008").toInt(),
          same(-10000000000000008));
    });

    test("toInt32", () {
      expect(new Int64(0).toInt32(), new Int32(0));
      expect(new Int64(1).toInt32(), new Int32(1));
      expect(new Int64(-1).toInt32(), new Int32(-1));
      expect(new Int64(2147483647).toInt32(), new Int32(2147483647));
      expect(new Int64(2147483648).toInt32(), new Int32(-2147483648));
      expect(new Int64(2147483649).toInt32(), new Int32(-2147483647));
      expect(new Int64(2147483650).toInt32(), new Int32(-2147483646));
      expect(new Int64(-2147483648).toInt32(), new Int32(-2147483648));
      expect(new Int64(-2147483649).toInt32(), new Int32(2147483647));
      expect(new Int64(-2147483650).toInt32(), new Int32(2147483646));
      expect(new Int64(-2147483651).toInt32(), new Int32(2147483645));
    });
  });

  test("JavaScript 53-bit integer boundary", () {
    Int64 _factorial(Int64 n) {
      if (n.isZero) {
        return new Int64(1);
      } else {
        return n * _factorial(n - new Int64(1));
      }
    }
    Int64 fact18 = _factorial(new Int64(18));
    Int64 fact17 = _factorial(new Int64(17));
    expect(fact18 ~/ fact17, new Int64(18));
  });

  test("min, max values", () {
    expect(new Int64(1) << 63, Int64.MIN_VALUE);
    expect(-(Int64.MIN_VALUE + new Int64(1)), Int64.MAX_VALUE);
  });

  group("parse", () {
    test("parseRadix10", () {
      checkInt(int x) {
        expect(Int64.parseRadix('$x', 10), new Int64(x));
      }
      checkInt(0);
      checkInt(1);
      checkInt(-1);
      checkInt(1000);
      checkInt(12345678);
      checkInt(-12345678);
      checkInt(2147483647);
      checkInt(2147483648);
      checkInt(-2147483647);
      checkInt(-2147483648);
      checkInt(4294967295);
      checkInt(4294967296);
      checkInt(-4294967295);
      checkInt(-4294967296);
      expect(() => Int64.parseRadix('xyzzy', -1), throwsArgumentError);
      expect(() => Int64.parseRadix('plugh', 10),
          throwsA(new isInstanceOf<FormatException>()));
    });

    test("parseRadix", () {
      check(String s, int r, String x) {
        expect(Int64.parseRadix(s, r).toString(), x);
      }
      check('ghoul', 36, '27699213');
      check('ghoul', 35, '24769346');
      // Min and max value.
      check("-9223372036854775808", 10, "-9223372036854775808");
      check("9223372036854775807", 10, "9223372036854775807");
      // Overflow during parsing.
      check("9223372036854775808", 10, "-9223372036854775808");
    });

    test("parseRadixN", () {
      check(String s, int r) {
        expect(Int64.parseRadix(s, r).toRadixString(r), s);
      }
      check("2ppp111222333", 33);  // This value & radix requires three chunks.
    });
  });

  group("string representation", () {
    test("toString", () {
      expect(new Int64(0).toString(), "0");
      expect(new Int64(1).toString(), "1");
      expect(new Int64(-1).toString(), "-1");
      expect(new Int64(-10).toString(), "-10");
      expect(Int64.MIN_VALUE.toString(), "-9223372036854775808");
      expect(Int64.MAX_VALUE.toString(), "9223372036854775807");

      int top = 922337201;
      int bottom = 967490662;
      Int64 fullnum = (new Int64(1000000000) * new Int64(top)) +
          new Int64(bottom);
      expect(fullnum.toString(), "922337201967490662");
      expect((-fullnum).toString(), "-922337201967490662");
      expect(new Int64(123456789).toString(), "123456789");
    });

    test("toHexString", () {
      Int64 deadbeef12341234 = new Int64.fromInts(0xDEADBEEF, 0x12341234);
      expect(Int64.ZERO.toHexString(), "0");
      expect(deadbeef12341234.toHexString(), "DEADBEEF12341234");
      expect(new Int64.fromInts(0x17678A7, 0xDEF01234).toHexString(),
          "17678A7DEF01234");
      expect(new Int64(123456789).toHexString(), "75BCD15");
    });

    test("toRadixString", () {
      expect(new Int64(123456789).toRadixString(5), "223101104124");
      expect(Int64.MIN_VALUE.toRadixString(2),
          "-1000000000000000000000000000000000000000000000000000000000000000");
      expect(Int64.MIN_VALUE.toRadixString(3),
          "-2021110011022210012102010021220101220222");
      expect(Int64.MIN_VALUE.toRadixString(4),
          "-20000000000000000000000000000000");
      expect(Int64.MIN_VALUE.toRadixString(5), "-1104332401304422434310311213");
      expect(Int64.MIN_VALUE.toRadixString(6), "-1540241003031030222122212");
      expect(Int64.MIN_VALUE.toRadixString(7), "-22341010611245052052301");
      expect(Int64.MIN_VALUE.toRadixString(8), "-1000000000000000000000");
      expect(Int64.MIN_VALUE.toRadixString(9), "-67404283172107811828");
      expect(Int64.MIN_VALUE.toRadixString(10), "-9223372036854775808");
      expect(Int64.MIN_VALUE.toRadixString(11), "-1728002635214590698");
      expect(Int64.MIN_VALUE.toRadixString(12), "-41a792678515120368");
      expect(Int64.MIN_VALUE.toRadixString(13), "-10b269549075433c38");
      expect(Int64.MIN_VALUE.toRadixString(14), "-4340724c6c71dc7a8");
      expect(Int64.MIN_VALUE.toRadixString(15), "-160e2ad3246366808");
      expect(Int64.MIN_VALUE.toRadixString(16), "-8000000000000000");
      expect(Int64.MAX_VALUE.toRadixString(2),
          "111111111111111111111111111111111111111111111111111111111111111");
      expect(Int64.MAX_VALUE.toRadixString(3),
          "2021110011022210012102010021220101220221");
      expect(Int64.MAX_VALUE.toRadixString(4),
          "13333333333333333333333333333333");
      expect(Int64.MAX_VALUE.toRadixString(5), "1104332401304422434310311212");
      expect(Int64.MAX_VALUE.toRadixString(6), "1540241003031030222122211");
      expect(Int64.MAX_VALUE.toRadixString(7), "22341010611245052052300");
      expect(Int64.MAX_VALUE.toRadixString(8), "777777777777777777777");
      expect(Int64.MAX_VALUE.toRadixString(9), "67404283172107811827");
      expect(Int64.MAX_VALUE.toRadixString(10), "9223372036854775807");
      expect(Int64.MAX_VALUE.toRadixString(11), "1728002635214590697");
      expect(Int64.MAX_VALUE.toRadixString(12), "41a792678515120367");
      expect(Int64.MAX_VALUE.toRadixString(13), "10b269549075433c37");
      expect(Int64.MAX_VALUE.toRadixString(14), "4340724c6c71dc7a7");
      expect(Int64.MAX_VALUE.toRadixString(15), "160e2ad3246366807");
      expect(Int64.MAX_VALUE.toRadixString(16), "7fffffffffffffff");
    });
  });
}
