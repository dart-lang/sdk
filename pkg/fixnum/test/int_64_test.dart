// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library int64test;
import 'package:fixnum/fixnum.dart';
import 'package:unittest/unittest.dart';

void main() {
  group("arithmetic operators", () {
    int64 n1 = new int64.fromInt(1234);
    int64 n2 = new int64.fromInt(9876);
    int64 n3 = new int64.fromInt(-1234);
    int64 n4 = new int64.fromInt(-9876);
    int64 n5 = new int64.fromInts(0x12345678, 0xabcdabcd);
    int64 n6 = new int64.fromInts(0x77773333, 0x22224444);

    test("+", () {
      expect(n1 + n2, new int64.fromInt(11110));
      expect(n3 + n2, new int64.fromInt(8642));
      expect(n3 + n4, new int64.fromInt(-11110));
      expect(n5 + n6, new int64.fromInts(0x89ab89ab, 0xcdeff011));
      expect(int64.MAX_VALUE + 1, int64.MIN_VALUE);
    });

    test("-", () {
      expect(n1 - n2, new int64.fromInt(-8642));
      expect(n3 - n2, new int64.fromInt(-11110));
      expect(n3 - n4, new int64.fromInt(8642));
      expect(n5 - n6, new int64.fromInts(0x9abd2345, 0x89ab6789));
      expect(int64.MIN_VALUE - 1, int64.MAX_VALUE);
    });

    test("unary -", () {
      expect(-n1, new int64.fromInt(-1234));
      expect(-int64.ZERO, int64.ZERO);
    });

    test("*", () {
      expect(new int64.fromInt(1111) * new int64.fromInt(3),
          new int64.fromInt(3333));
      expect(new int64.fromInt(1111) * new int64.fromInt(-3),
          new int64.fromInt(-3333));
      expect(new int64.fromInt(-1111) * new int64.fromInt(3),
          new int64.fromInt(-3333));
      expect(new int64.fromInt(-1111) * new int64.fromInt(-3),
          new int64.fromInt(3333));
      expect(new int64.fromInt(100) * new int64.fromInt(0),
          new int64.fromInt(0));

      expect(new int64.fromInts(0x12345678, 0x12345678) *
          new int64.fromInts(0x1234, 0x12345678),
          new int64.fromInts(0x7ff63f7c, 0x1df4d840));
      expect(new int64.fromInts(0xf2345678, 0x12345678) *
          new int64.fromInts(0x1234, 0x12345678),
          new int64.fromInts(0x7ff63f7c, 0x1df4d840));
      expect(new int64.fromInts(0xf2345678, 0x12345678) *
          new int64.fromInts(0xffff1234, 0x12345678),
          new int64.fromInts(0x297e3f7c, 0x1df4d840));

      // RHS int32
      expect((new int64.fromInt(123456789) * new int32.fromInt(987654321)),
          new int64.fromInts(0x1b13114, 0xfbff5385));
      expect((new int64.fromInt(123456789) * new int32.fromInt(987654321)),
          new int64.fromInts(0x1b13114, 0xfbff5385));

      // Wraparound
      expect((new int64.fromInt(123456789) * new int64.fromInt(987654321)),
          new int64.fromInts(0x1b13114, 0xfbff5385));

      expect(int64.MIN_VALUE * new int64.fromInt(2), new int64.fromInt(0));
      expect(int64.MIN_VALUE * new int64.fromInt(1), int64.MIN_VALUE);
      expect(int64.MIN_VALUE * new int64.fromInt(-1), int64.MIN_VALUE);
    });

    test("~/", () {
      int64 deadBeef = new int64.fromInts(0xDEADBEEF, 0xDEADBEEF);
      int64 ten = new int64.fromInt(10);

      expect(deadBeef ~/ ten, new int64.fromInts(0xfcaaf97e, 0x63115fe5));
      expect(int64.ONE ~/ int64.TWO, int64.ZERO);
      expect(int64.MAX_VALUE ~/ int64.TWO,
          new int64.fromInts(0x3fffffff, 0xffffffff));
      expect(int64.ZERO ~/ new int64.fromInt(1000), int64.ZERO);
      expect(int64.MIN_VALUE ~/ int64.MIN_VALUE, int64.ONE);
      expect(new int64.fromInt(1000) ~/ int64.MIN_VALUE, int64.ZERO);
      expect(int64.MIN_VALUE ~/ new int64.fromInt(8192),
          new int64.fromInt(-1125899906842624));
      expect(int64.MIN_VALUE ~/ new int64.fromInt(8193),
          new int64.fromInt(-1125762484664320));
      expect(new int64.fromInt(-1000) ~/ new int64.fromInt(8192), int64.ZERO);
      expect(new int64.fromInt(-1000) ~/ new int64.fromInt(8193), int64.ZERO);
      expect(new int64.fromInt(-1000000000) ~/ new int64.fromInt(8192),
          new int64.fromInt(-122070));
      expect(new int64.fromInt(-1000000000) ~/ new int64.fromInt(8193),
          new int64.fromInt(-122055));
      expect(new int64.fromInt(1000000000) ~/ new int64.fromInt(8192),
          new int64.fromInt(122070));
      expect(new int64.fromInt(1000000000) ~/ new int64.fromInt(8193),
          new int64.fromInt(122055));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x00000400),
          new int64.fromInts(0x1fffff, 0xffffffff));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x00040000),
          new int64.fromInts(0x1fff, 0xffffffff));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x04000000),
          new int64.fromInts(0x1f, 0xffffffff));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000004, 0x00000000),
          new int64.fromInt(536870911));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000400, 0x00000000),
          new int64.fromInt(2097151));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00040000, 0x00000000),
          new int64.fromInt(8191));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x04000000, 0x00000000),
          new int64.fromInt(31));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x00000300),
          new int64.fromInts(0x2AAAAA, 0xAAAAAAAA));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x30000000),
          new int64.fromInts(0x2, 0xAAAAAAAA));
      expect(int64.MAX_VALUE ~/ new int64.fromInts(0x00300000, 0x00000000),
          new int64.fromInt(0x2AA));
      expect(int64.MAX_VALUE ~/ new int64.fromInt(0x123456),
          new int64.fromInts(0x708, 0x002E9501));
      expect(int64.MAX_VALUE % new int64.fromInt(0x123456),
          new int64.fromInt(0x3BDA9));
      expect(new int64.fromInt(5) ~/ new int64.fromInt(5),
          new int64.fromInt(1));
      expect(new int64.fromInt(1000) ~/ new int64.fromInt(3),
          new int64.fromInt(333));
      expect(new int64.fromInt(1000) ~/ new int64.fromInt(-3),
          new int64.fromInt(-333));
      expect(new int64.fromInt(-1000) ~/ new int64.fromInt(3),
          new int64.fromInt(-333));
      expect(new int64.fromInt(-1000) ~/ new int64.fromInt(-3),
          new int64.fromInt(333));
      expect(new int64.fromInt(3) ~/ new int64.fromInt(1000),
          new int64.fromInt(0));
      expect(new int64.fromInts( 0x12345678, 0x12345678) ~/
          new int64.fromInts(0x0, 0x123),
          new int64.fromInts(0x1003d0, 0xe84f5ae8));
      expect(new int64.fromInts(0x12345678, 0x12345678) ~/
          new int64.fromInts(0x1234, 0x12345678),
          new int64.fromInts(0x0, 0x10003));
      expect(new int64.fromInts(0xf2345678, 0x12345678) ~/
          new int64.fromInts(0x1234, 0x12345678),
          new int64.fromInts(0xffffffff, 0xffff3dfe));
      expect(new int64.fromInts(0xf2345678, 0x12345678) ~/
          new int64.fromInts(0xffff1234, 0x12345678),
          new int64.fromInts(0x0, 0xeda));
      expect(new int64.fromInt(829893893) ~/ new int32.fromInt(1919),
          new int32.fromInt(432461));
      expect(new int64.fromInt(829893893) ~/ new int64.fromInt(1919),
          new int32.fromInt(432461));
      expect(new int64.fromInt(829893893) ~/ 1919,
          new int32.fromInt(432461));
      expect(() => new int64.fromInt(1) ~/ new int64.fromInt(0),
          throwsA(new isInstanceOf<IntegerDivisionByZeroException>()));
      expect(int64.MIN_VALUE ~/ new int64.fromInt(2),
          new int64.fromInts(0xc0000000, 0x00000000));
      expect(int64.MIN_VALUE ~/ new int64.fromInt(1), int64.MIN_VALUE);
      expect(int64.MIN_VALUE ~/ new int64.fromInt(-1), int64.MIN_VALUE);
      expect(() => new int64.fromInt(17) ~/ int64.ZERO, throws);
      expect(() => new int64.fromInt(17) ~/ null, throws);
    });

    test("%", () {
      // Define % as Euclidean mod, with positive result for all arguments
      expect(int64.ZERO % new int64.fromInt(1000), new int64.fromInt(0));
      expect(int64.MIN_VALUE % int64.MIN_VALUE, new int64.fromInt(0));
      expect(new int64.fromInt(1000) % int64.MIN_VALUE,
          new int64.fromInt(1000));
      expect(int64.MIN_VALUE % new int64.fromInt(8192), new int64.fromInt(0));
      expect(int64.MIN_VALUE % new int64.fromInt(8193),
          new int64.fromInt(6145));
      expect(new int64.fromInt(-1000) % new int64.fromInt(8192),
          new int64.fromInt(7192));
      expect(new int64.fromInt(-1000) % new int64.fromInt(8193),
          new int64.fromInt(7193));
      expect(new int64.fromInt(-1000000000) % new int64.fromInt(8192),
          new int64.fromInt(5632));
      expect(new int64.fromInt(-1000000000) % new int64.fromInt(8193),
          new int64.fromInt(4808));
      expect(new int64.fromInt(1000000000) % new int64.fromInt(8192),
          new int64.fromInt(2560));
      expect(new int64.fromInt(1000000000) % new int64.fromInt(8193),
          new int64.fromInt(3385));
      expect(int64.MAX_VALUE % new int64.fromInts(0x00000000, 0x00000400),
          new int64.fromInts(0x0, 0x3ff));
      expect(int64.MAX_VALUE % new int64.fromInts(0x00000000, 0x00040000),
          new int64.fromInts(0x0, 0x3ffff));
      expect(int64.MAX_VALUE % new int64.fromInts(0x00000000, 0x04000000),
          new int64.fromInts(0x0, 0x3ffffff));
      expect(int64.MAX_VALUE % new int64.fromInts(0x00000004, 0x00000000),
          new int64.fromInts(0x3, 0xffffffff));
      expect(int64.MAX_VALUE % new int64.fromInts(0x00000400, 0x00000000),
          new int64.fromInts(0x3ff, 0xffffffff));
      expect(int64.MAX_VALUE % new int64.fromInts(0x00040000, 0x00000000),
          new int64.fromInts(0x3ffff, 0xffffffff));
      expect(int64.MAX_VALUE % new int64.fromInts(0x04000000, 0x00000000),
          new int64.fromInts(0x3ffffff, 0xffffffff));
      expect(new int64.fromInt(0x12345678).remainder(new int64.fromInt(0x22)),
          new int64.fromInt(0x12345678.remainder(0x22)));
      expect(new int64.fromInt(0x12345678).remainder(new int64.fromInt(-0x22)),
          new int64.fromInt(0x12345678.remainder(-0x22)));
      expect(new int64.fromInt(-0x12345678).remainder(new int64.fromInt(-0x22)),
          new int64.fromInt(-0x12345678.remainder(-0x22)));
      expect(new int64.fromInt(-0x12345678).remainder(new int64.fromInt(0x22)),
          new int64.fromInt(-0x12345678.remainder(0x22)));
      expect(new int32.fromInt(0x12345678).remainder(new int64.fromInt(0x22)),
          new int64.fromInt(0x12345678.remainder(0x22)));
    });
  });

  group("comparison operators", () {
    int64 largeNeg = new int64.fromInts(0x82341234, 0x0);
    int64 largePos = new int64.fromInts(0x12341234, 0x0);
    int64 largePosPlusOne = largePos + new int64.fromInt(1);

    test("<", () {
      expect(new int64.fromInt(10) < new int64.fromInt(11), true);
      expect(new int64.fromInt(10) < new int64.fromInt(10), false);
      expect(new int64.fromInt(12) < new int64.fromInt(11), false);
      expect(new int64.fromInt(-10) < new int64.fromInt(-11), false);
      expect(int64.MIN_VALUE < new int64.fromInt(0), true);
      expect(largeNeg < largePos, true);
      expect(largePos < largePosPlusOne, true);
      expect(largePos < largePos, false);
      expect(largePosPlusOne < largePos, false);
      expect(int64.MIN_VALUE < int64.MAX_VALUE, true);
      expect(int64.MAX_VALUE < int64.MIN_VALUE, false);
      expect(() => new int64.fromInt(17) < null, throwsArgumentError);
    });

    test("<=", () {
      expect(new int64.fromInt(10) <= new int64.fromInt(11), true);
      expect(new int64.fromInt(10) <= new int64.fromInt(10), true);
      expect(new int64.fromInt(12) <= new int64.fromInt(11), false);
      expect(new int64.fromInt(-10) <= new int64.fromInt(-11), false);
      expect(new int64.fromInt(-10) <= new int64.fromInt(-10), true);
      expect(largeNeg <= largePos, true);
      expect(largePos <= largeNeg, false);
      expect(largePos <= largePosPlusOne, true);
      expect(largePos <= largePos, true);
      expect(largePosPlusOne <= largePos, false);
      expect(int64.MIN_VALUE <= int64.MAX_VALUE, true);
      expect(int64.MAX_VALUE <= int64.MIN_VALUE, false);
      expect(() => new int64.fromInt(17) <= null, throwsArgumentError);
    });

    test("==", () {
      expect(new int64.fromInt(10) == new int64.fromInt(11), false);
      expect(new int64.fromInt(10) == new int64.fromInt(10), true);
      expect(new int64.fromInt(12) == new int64.fromInt(11), false);
      expect(new int64.fromInt(-10) == new int64.fromInt(-10), true);
      expect(new int64.fromInt(-10) != new int64.fromInt(-10), false);
      expect(largePos == largePos, true);
      expect(largePos == largePosPlusOne, false);
      expect(largePosPlusOne == largePos, false);
      expect(int64.MIN_VALUE == int64.MAX_VALUE, false);
      expect(new int64.fromInt(17) == null, false);
    });

    test(">=", () {
      expect(new int64.fromInt(10) >= new int64.fromInt(11), false);
      expect(new int64.fromInt(10) >= new int64.fromInt(10), true);
      expect(new int64.fromInt(12) >= new int64.fromInt(11), true);
      expect(new int64.fromInt(-10) >= new int64.fromInt(-11), true);
      expect(new int64.fromInt(-10) >= new int64.fromInt(-10), true);
      expect(largePos >= largeNeg, true);
      expect(largeNeg >= largePos, false);
      expect(largePos >= largePosPlusOne, false);
      expect(largePos >= largePos, true);
      expect(largePosPlusOne >= largePos, true);
      expect(int64.MIN_VALUE >= int64.MAX_VALUE, false);
      expect(int64.MAX_VALUE >= int64.MIN_VALUE, true);
      expect(() => new int64.fromInt(17) >= null, throwsArgumentError);
    });

    test(">", () {
      expect(new int64.fromInt(10) > new int64.fromInt(11), false);
      expect(new int64.fromInt(10) > new int64.fromInt(10), false);
      expect(new int64.fromInt(12) > new int64.fromInt(11), true);
      expect(new int64.fromInt(-10) > new int64.fromInt(-11), true);
      expect(new int64.fromInt(10) > new int64.fromInt(-11), true);
      expect(new int64.fromInt(-10) > new int64.fromInt(11), false);
      expect(largePos > largeNeg, true);
      expect(largeNeg > largePos, false);
      expect(largePos > largePosPlusOne, false);
      expect(largePos > largePos, false);
      expect(largePosPlusOne > largePos, true);
      expect(new int64.fromInt(0) > int64.MIN_VALUE, true);
      expect(int64.MIN_VALUE > int64.MAX_VALUE, false);
      expect(int64.MAX_VALUE > int64.MIN_VALUE, true);
      expect(() => new int64.fromInt(17) > null, throwsArgumentError);
    });
  });

  group("bitwise operators", () {
    int64 n1 = new int64.fromInt(1234);
    int64 n2 = new int64.fromInt(9876);
    int64 n3 = new int64.fromInt(-1234);
    int64 n4 = new int64.fromInt(0x1234) << 32;
    int64 n5 = new int64.fromInt(0x9876) << 32;

    test("&", () {
      expect(n1 & n2, new int64.fromInt(1168));
      expect(n3 & n2, new int64.fromInt(8708));
      expect(n4 & n5, new int64.fromInt(0x1034) << 32);
      expect(() => n1 & null, throws);
    });

    test("|", () {
      expect(n1 | n2, new int64.fromInt(9942));
      expect(n3 | n2, new int64.fromInt(-66));
      expect(n4 | n5, new int64.fromInt(0x9a76) << 32);
      expect(() => n1 | null, throws);
    });

    test("^", () {
      expect(n1 ^ n2, new int64.fromInt(8774));
      expect(n3 ^ n2, new int64.fromInt(-8774));
      expect(n4 ^ n5, new int64.fromInt(0x8a42) << 32);
      expect(() => n1 ^ null, throws);
    });

    test("~", () {
      expect(-new int64.fromInt(1), new int64.fromInt(-1));
      expect(-new int64.fromInt(-1), new int64.fromInt(1));
      expect(-int64.MIN_VALUE, int64.MIN_VALUE);

      expect(~n1, new int64.fromInt(-1235));
      expect(~n2, new int64.fromInt(-9877));
      expect(~n3, new int64.fromInt(1233));
      expect(~n4, new int64.fromInts(0xffffedcb, 0xffffffff));
      expect(~n5, new int64.fromInts(0xffff6789, 0xffffffff));
    });
  });

  group("bitshift operators", () {
    test("<<", () {
      expect(new int64.fromInts(0x12341234, 0x45674567) << 10,
          new int64.fromInts(0xd048d115, 0x9d159c00));
      expect(new int64.fromInts(0x92341234, 0x45674567) << 10,
          new int64.fromInts(0xd048d115, 0x9d159c00));
      expect(new int64.fromInt(-1) << 5, new int64.fromInt(-32));
      expect(new int64.fromInt(-1) << 0, new int64.fromInt(-1));
      expect(() => new int64.fromInt(17) << -1, throwsArgumentError);
      expect(() => new int64.fromInt(17) << null, throws);
    });

    test(">>", () {
      expect((int64.MIN_VALUE >> 13).toString(), "-1125899906842624");
      expect(new int64.fromInts(0x12341234, 0x45674567) >> 10,
          new int64.fromInts(0x48d04, 0x8d1159d1));
      expect(new int64.fromInts(0x92341234, 0x45674567) >> 10,
          new int64.fromInts(0xffe48d04, 0x8d1159d1));
      expect(new int64.fromInts(0xFFFFFFF, 0xFFFFFFFF) >> 34,
          new int64.fromInt(67108863));
      for (int n = 0; n <= 66; n++) {
        expect(new int64.fromInt(-1) >> n, new int64.fromInt(-1));
      }
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 8,
          new int64.fromInts(0x00723456, 0x789abcde));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 16,
          new int64.fromInts(0x00007234, 0x56789abc));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 24,
          new int64.fromInts(0x00000072, 0x3456789a));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 28,
          new int64.fromInts(0x00000007, 0x23456789));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 32,
          new int64.fromInts(0x00000000, 0x72345678));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 36,
          new int64.fromInts(0x00000000, 0x07234567));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 40,
          new int64.fromInts(0x00000000, 0x00723456));
      expect(new int64.fromInts(0x72345678, 0x9abcde00) >> 44,
          new int64.fromInts(0x00000000, 0x00072345));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0) >> 48,
          new int64.fromInts(0x00000000, 0x00007234));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 8,
          new int64.fromInts(0xff923456, 0x789abcde));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 16,
          new int64.fromInts(0xffff9234, 0x56789abc));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 24,
          new int64.fromInts(0xffffff92, 0x3456789a));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 28,
          new int64.fromInts(0xfffffff9, 0x23456789));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 32,
          new int64.fromInts(0xffffffff, 0x92345678));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 36,
          new int64.fromInts(0xffffffff, 0xf9234567));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 40,
          new int64.fromInts(0xffffffff, 0xff923456));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 44,
          new int64.fromInts(0xffffffff, 0xfff92345));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0) >> 48,
          new int64.fromInts(0xffffffff, 0xffff9234));
      expect(() => new int64.fromInt(17) >> -1, throwsArgumentError);
      expect(() => new int64.fromInt(17) >> null, throws);
    });

    test("shiftRightUnsigned", () {
      expect(new int64.fromInts(0x12341234, 0x45674567).shiftRightUnsigned(10),
          new int64.fromInts(0x48d04, 0x8d1159d1));
      expect(new int64.fromInts(0x92341234, 0x45674567).shiftRightUnsigned(10),
          new int64.fromInts(0x248d04, 0x8d1159d1));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(8),
          new int64.fromInts(0x00723456, 0x789abcde));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(16),
          new int64.fromInts(0x00007234, 0x56789abc));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(24),
          new int64.fromInts(0x00000072, 0x3456789a));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(28),
          new int64.fromInts(0x00000007, 0x23456789));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(32),
          new int64.fromInts(0x00000000, 0x72345678));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(36),
          new int64.fromInts(0x00000000, 0x07234567));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(40),
          new int64.fromInts(0x00000000, 0x00723456));
      expect(new int64.fromInts(0x72345678, 0x9abcde00).shiftRightUnsigned(44),
          new int64.fromInts(0x00000000, 0x00072345));
      expect(new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(48),
          new int64.fromInts(0x00000000, 0x00007234));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(8),
          new int64.fromInts(0x00923456, 0x789abcde));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(16),
          new int64.fromInts(0x00009234, 0x56789abc));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(24),
          new int64.fromInts(0x00000092, 0x3456789a));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(28),
          new int64.fromInts(0x00000009, 0x23456789));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(32),
          new int64.fromInts(0x00000000, 0x92345678));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(36),
          new int64.fromInts(0x00000000, 0x09234567));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(40),
          new int64.fromInts(0x00000000, 0x00923456));
      expect(new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(44),
          new int64.fromInts(0x00000000, 0x00092345));
      expect(new int64.fromInts(0x00000000, 0x00009234),
          new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(48));
      expect(() => new int64.fromInt(17).shiftRightUnsigned(-1),
          throwsArgumentError);
      expect(() => new int64.fromInt(17).shiftRightUnsigned(null), throws);
    });

    test("overflow", () {
      expect((new int64.fromInt(1) << 63) >> 1,
          -new int64.fromInts(0x40000000, 0x00000000));
      expect((new int64.fromInt(-1) << 32) << 32, new int64.fromInt(0));
      expect(int64.MIN_VALUE << 0, int64.MIN_VALUE);
      expect(int64.MIN_VALUE << 1, new int64.fromInt(0));
      expect((-new int64.fromInts(8, 0)) >> 1,
          new int64.fromInts(0xfffffffc, 0x00000000));
      expect((-new int64.fromInts(8, 0)).shiftRightUnsigned(1),
          new int64.fromInts(0x7ffffffc, 0x0));
    });
  });

  group("type conversions", () {
    test("toInt", () {
      expect(new int64.fromInt(0).toInt(), 0);
      expect(new int64.fromInt(100).toInt(), 100);
      expect(new int64.fromInt(-100).toInt(), -100);
      expect(new int64.fromInt(2147483647).toInt(), 2147483647);
      expect(new int64.fromInt(2147483648).toInt(), 2147483648);
      expect(new int64.fromInt(-2147483647).toInt(), -2147483647);
      expect(new int64.fromInt(-2147483648).toInt(), -2147483648);
      expect(new int64.fromInt(4503599627370495).toInt(), 4503599627370495);
      expect(new int64.fromInt(4503599627370496).toInt(), 4503599627370496);
      expect(new int64.fromInt(-4503599627370495).toInt(), -4503599627370495);
      expect(new int64.fromInt(-4503599627370496).toInt(), -4503599627370496);
    });

    test("toInt32", () {
      expect(new int64.fromInt(0).toInt32(), new int32.fromInt(0));
      expect(new int64.fromInt(1).toInt32(), new int32.fromInt(1));
      expect(new int64.fromInt(-1).toInt32(), new int32.fromInt(-1));
      expect(new int64.fromInt(2147483647).toInt32(),
          new int32.fromInt(2147483647));
      expect(new int64.fromInt(2147483648).toInt32(),
          new int32.fromInt(-2147483648));
      expect(new int64.fromInt(2147483649).toInt32(),
          new int32.fromInt(-2147483647));
      expect(new int64.fromInt(2147483650).toInt32(),
          new int32.fromInt(-2147483646));
      expect(new int64.fromInt(-2147483648).toInt32(),
          new int32.fromInt(-2147483648));
      expect(new int64.fromInt(-2147483649).toInt32(),
          new int32.fromInt(2147483647));
      expect(new int64.fromInt(-2147483650).toInt32(),
          new int32.fromInt(2147483646));
      expect(new int64.fromInt(-2147483651).toInt32(),
          new int32.fromInt(2147483645));
    });
  });

  test("JavaScript 53-bit integer boundary", () {
    int64 _factorial(int64 n) {
      if (n.isZero) {
        return new int64.fromInt(1);
      } else {
        return n * _factorial(n - new int64.fromInt(1));
      }
    }
    int64 fact18 = _factorial(new int64.fromInt(18));
    int64 fact17 = _factorial(new int64.fromInt(17));
    expect(fact18 ~/ fact17, new int64.fromInt(18));
  });

  test("min, max values", () {
    expect(new int64.fromInt(1) << 63, int64.MIN_VALUE);
    expect(-(int64.MIN_VALUE + new int64.fromInt(1)), int64.MAX_VALUE);
  });

  group("string representation", () {
    test("toString", () {
      expect(new int64.fromInt(0).toString(), "0");
      expect(new int64.fromInt(1).toString(), "1");
      expect(new int64.fromInt(-1).toString(), "-1");
      expect(new int64.fromInt(-10).toString(), "-10");
      expect(int64.MIN_VALUE.toString(), "-9223372036854775808");
      expect(int64.MAX_VALUE.toString(), "9223372036854775807");

      int top = 922337201;
      int bottom = 967490662;
      int64 fullnum = (new int64.fromInt(1000000000) * new int64.fromInt(top)) +
          new int64.fromInt(bottom);
      expect(fullnum.toString(), "922337201967490662");
      expect((-fullnum).toString(), "-922337201967490662");
      expect(new int64.fromInt(123456789).toString(), "123456789");
    });

    test("toHexString", () {
      int64 deadbeef12341234 = new int64.fromInts(0xDEADBEEF, 0x12341234);
      expect(int64.ZERO.toHexString(), "0");
      expect(deadbeef12341234.toHexString(), "DEADBEEF12341234");
      expect(new int64.fromInts(0x17678A7, 0xDEF01234).toHexString(),
          "17678A7DEF01234");
      expect(new int64.fromInt(123456789).toHexString(), "75BCD15");
    });

    test("toRadixString", () {
      expect(new int64.fromInt(123456789).toRadixString(5), "223101104124");
      expect(int64.MIN_VALUE.toRadixString(2),
          "-1000000000000000000000000000000000000000000000000000000000000000");
      expect(int64.MIN_VALUE.toRadixString(3),
          "-2021110011022210012102010021220101220222");
      expect(int64.MIN_VALUE.toRadixString(4),
          "-20000000000000000000000000000000");
      expect(int64.MIN_VALUE.toRadixString(5), "-1104332401304422434310311213");
      expect(int64.MIN_VALUE.toRadixString(6), "-1540241003031030222122212");
      expect(int64.MIN_VALUE.toRadixString(7), "-22341010611245052052301");
      expect(int64.MIN_VALUE.toRadixString(8), "-1000000000000000000000");
      expect(int64.MIN_VALUE.toRadixString(9), "-67404283172107811828");
      expect(int64.MIN_VALUE.toRadixString(10), "-9223372036854775808");
      expect(int64.MIN_VALUE.toRadixString(11), "-1728002635214590698");
      expect(int64.MIN_VALUE.toRadixString(12), "-41A792678515120368");
      expect(int64.MIN_VALUE.toRadixString(13), "-10B269549075433C38");
      expect(int64.MIN_VALUE.toRadixString(14), "-4340724C6C71DC7A8");
      expect(int64.MIN_VALUE.toRadixString(15), "-160E2AD3246366808");
      expect(int64.MIN_VALUE.toRadixString(16), "-8000000000000000");
      expect(int64.MAX_VALUE.toRadixString(2),
          "111111111111111111111111111111111111111111111111111111111111111");
      expect(int64.MAX_VALUE.toRadixString(3),
          "2021110011022210012102010021220101220221");
      expect(int64.MAX_VALUE.toRadixString(4),
          "13333333333333333333333333333333");
      expect(int64.MAX_VALUE.toRadixString(5), "1104332401304422434310311212");
      expect(int64.MAX_VALUE.toRadixString(6), "1540241003031030222122211");
      expect(int64.MAX_VALUE.toRadixString(7), "22341010611245052052300");
      expect(int64.MAX_VALUE.toRadixString(8), "777777777777777777777");
      expect(int64.MAX_VALUE.toRadixString(9), "67404283172107811827");
      expect(int64.MAX_VALUE.toRadixString(10), "9223372036854775807");
      expect(int64.MAX_VALUE.toRadixString(11), "1728002635214590697");
      expect(int64.MAX_VALUE.toRadixString(12), "41A792678515120367");
      expect(int64.MAX_VALUE.toRadixString(13), "10B269549075433C37");
      expect(int64.MAX_VALUE.toRadixString(14), "4340724C6C71DC7A7");
      expect(int64.MAX_VALUE.toRadixString(15), "160E2AD3246366807");
      expect(int64.MAX_VALUE.toRadixString(16), "7FFFFFFFFFFFFFFF");
    });
  });
}
