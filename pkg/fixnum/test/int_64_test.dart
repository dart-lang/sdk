// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('int64test');
#import('../fixnum.dart');

void main() {
  testAdditive();
  testBitOps();
  testComparisons();
  testConversions();
  testDiv();
  testFactorial();
  testMinMax();
  testMod();
  testMultiplicative();
  testNegate();
  testShift();
  testToHexString();
  testToString();
}

void testAdditive() {
  {
    int64 n1 = new int64.fromInt(1234);
    int64 n2 = new int64.fromInt(9876);
    Expect.equals(new int64.fromInt(11110), n1 + n2);
    Expect.equals(new int64.fromInt(-8642), n1 - n2);
  }

  {
    int64 n1 = new int64.fromInt(-1234);
    int64 n2 = new int64.fromInt(9876);
    Expect.equals(new int64.fromInt(8642), n1 + n2);
    Expect.equals(new int64.fromInt(-11110), n1 - n2);
  }

  {
    int64 n1 = new int64.fromInt(-1234);
    int64 n2 = new int64.fromInt(-9876);
    Expect.equals(new int64.fromInt(-11110), n1 + n2);
    Expect.equals(new int64.fromInt(8642), n1 - n2);
  }

  {
    int64 n1 = new int64.fromInts(0x12345678, 0xabcdabcd);
    int64 n2 = new int64.fromInts(0x77773333, 0x22224444);
    Expect.equals(new int64.fromInts(0x89ab89ab, 0xcdeff011), n1 + n2);
    Expect.equals(new int64.fromInts(0x9abd2345, 0x89ab6789), n1 - n2);
  }
}

void testBitOps() {
  {
    int64 n1 = new int64.fromInt(1234);
    int64 n2 = new int64.fromInt(9876);

    Expect.equals(new int64.fromInt(1168), n1 & n2);
    Expect.equals(new int64.fromInt(9942), n1 | n2);
    Expect.equals(new int64.fromInt(8774), n1 ^ n2);
    Expect.equals(new int64.fromInt(-1235), ~n1);
    Expect.equals(new int64.fromInt(-9877), ~n2);
  }

  {
    int64 n1 = new int64.fromInt(-1234);
    int64 n2 = new int64.fromInt(9876);
    Expect.equals(new int64.fromInt(8708), n1 & n2);
    Expect.equals(new int64.fromInt(-66), n1 | n2);
    Expect.equals(new int64.fromInt(-8774), n1 ^ n2);
    Expect.equals(new int64.fromInt(1233), ~n1);
    Expect.equals(new int64.fromInt(-9877), ~n2);
  }

  {
    int64 n1 = new int64.fromInt(0x1234) << 32;
    int64 n2 = new int64.fromInt(0x9876) << 32;
    Expect.equals(new int64.fromInt(0x1034) << 32, n1 & n2);
    Expect.equals(new int64.fromInt(0x9a76) << 32, n1 | n2);
    Expect.equals(new int64.fromInt(0x8a42) << 32, n1 ^ n2);
    Expect.equals(new int64.fromInts(0xffffedcb, 0xffffffff), ~n1);
    Expect.equals(new int64.fromInts(0xffff6789, 0xffffffff), ~n2);
  }
}

void testComparisons() {
  Expect.isTrue(new int64.fromInt(10) < new int64.fromInt(11));
  Expect.isTrue(new int64.fromInt(10) <= new int64.fromInt(11));
  Expect.isTrue(!(new int64.fromInt(10) == new int64.fromInt(11)));
  Expect.isTrue(!(new int64.fromInt(10) >= new int64.fromInt(11)));
  Expect.isTrue(!(new int64.fromInt(10) > new int64.fromInt(11)));

  Expect.isTrue(!(new int64.fromInt(10) < new int64.fromInt(10)));
  Expect.isTrue(new int64.fromInt(10) <= new int64.fromInt(10));
  Expect.isTrue(new int64.fromInt(10) == new int64.fromInt(10));
  Expect.isTrue(new int64.fromInt(10) >= new int64.fromInt(10));
  Expect.isTrue(!(new int64.fromInt(10) > new int64.fromInt(10)));

  Expect.isTrue(!(new int64.fromInt(12) < new int64.fromInt(11)));
  Expect.isTrue(!(new int64.fromInt(12) <= new int64.fromInt(11)));
  Expect.isTrue(!(new int64.fromInt(12) == new int64.fromInt(11)));
  Expect.isTrue(new int64.fromInt(12) >= new int64.fromInt(11));
  Expect.isTrue(new int64.fromInt(12) > new int64.fromInt(11));
  
  Expect.isTrue(new int64.fromInt(-10) > new int64.fromInt(-11));
  Expect.isTrue(new int64.fromInt(10) > new int64.fromInt(-11));
  Expect.isTrue(!(new int64.fromInt(-10) > new int64.fromInt(11)));
  Expect.isTrue(new int64.fromInt(-10) >= new int64.fromInt(-11));
  Expect.isTrue(new int64.fromInt(-10) >= new int64.fromInt(-10));
  Expect.isTrue(!(new int64.fromInt(-10) < new int64.fromInt(-11)));
  Expect.isTrue(!(new int64.fromInt(-10) <= new int64.fromInt(-11)));
  Expect.isTrue(new int64.fromInt(-10) <= new int64.fromInt(-10));
  Expect.isTrue(new int64.fromInt(-10) == new int64.fromInt(-10));
  Expect.isTrue(!(new int64.fromInt(-10) != new int64.fromInt(-10)));

  // the following three comparisons cannot be implemented by
  // subtracting the arguments, because the subtraction causes an overflow
  int64 largeNeg = new int64.fromInts(0x82341234, 0x0);
  int64 largePos = new int64.fromInts(0x12341234, 0x0);
  Expect.isTrue(largeNeg < largePos);

  Expect.isTrue(int64.MIN_VALUE < new int64.fromInt(0));
  Expect.isTrue(new int64.fromInt(0) > int64.MIN_VALUE);

  int64 largePosPlusOne = largePos + new int64.fromInt(1);

  Expect.isTrue(largePos < largePosPlusOne);
  Expect.isTrue(largePos <= largePosPlusOne);
  Expect.isTrue(!(largePos == largePosPlusOne));
  Expect.isTrue(!(largePos >= largePosPlusOne));
  Expect.isTrue(!(largePos > largePosPlusOne));

  Expect.isTrue(!(largePos < largePos));
  Expect.isTrue(largePos <= largePos);
  Expect.isTrue(largePos == largePos);
  Expect.isTrue(largePos >= largePos);
  Expect.isTrue(!(largePos > largePos));

  Expect.isTrue(!(largePosPlusOne < largePos));
  Expect.isTrue(!(largePosPlusOne <= largePos));
  Expect.isTrue(!(largePosPlusOne == largePos));
  Expect.isTrue(largePosPlusOne >= largePos);
  Expect.isTrue(largePosPlusOne > largePos);
  
  try {
    new int64.fromInt(17) < null;
    Expect.fail("x < null should throw NullPointerException");
  } catch (NullPointerException e) {
  }

  try {
    new int64.fromInt(17) <= null;
    Expect.fail("x <= null should throw NullPointerException");
  } catch (NullPointerException e) {
  }

  try {
    new int64.fromInt(17) > null;
    Expect.fail("x > null should throw NullPointerException");
  } catch (NullPointerException e) {
  }

  try {
    new int64.fromInt(17) < null;
    Expect.fail("x >= null should throw NullPointerException");
  } catch (NullPointerException e) {
  }

  Expect.isFalse(new int64.fromInt(17) == null);
}

void testConversions() {
  Expect.equals(0, new int64.fromInt(0).toInt());
  Expect.equals(100, new int64.fromInt(100).toInt());
  Expect.equals(-100, new int64.fromInt(-100).toInt());
  Expect.equals(2147483647, new int64.fromInt(2147483647).toInt());
  Expect.equals(2147483648, new int64.fromInt(2147483648).toInt());
  Expect.equals(-2147483647, new int64.fromInt(-2147483647).toInt());
  Expect.equals(-2147483648, new int64.fromInt(-2147483648).toInt());
  Expect.equals(4503599627370495, new int64.fromInt(4503599627370495).toInt());
  Expect.equals(4503599627370496, new int64.fromInt(4503599627370496).toInt());
  Expect.equals(-4503599627370495,
      new int64.fromInt(-4503599627370495).toInt());
  Expect.equals(-4503599627370496,
      new int64.fromInt(-4503599627370496).toInt());

  Expect.equals(new int32.fromInt(0), new int64.fromInt(0).toInt32());
  Expect.equals(new int32.fromInt(1), new int64.fromInt(1).toInt32());
  Expect.equals(new int32.fromInt(-1), new int64.fromInt(-1).toInt32());
  Expect.equals(new int32.fromInt(2147483647),
    new int64.fromInt(2147483647).toInt32());
  Expect.equals(new int32.fromInt(-2147483648),
      new int64.fromInt(2147483648).toInt32());
  Expect.equals(new int32.fromInt(-2147483647),
      new int64.fromInt(2147483649).toInt32());
  Expect.equals(new int32.fromInt(-2147483646),
      new int64.fromInt(2147483650).toInt32());

  Expect.equals(new int32.fromInt(-2147483648),
      new int64.fromInt(-2147483648).toInt32());
  Expect.equals(new int32.fromInt(2147483647),
      new int64.fromInt(-2147483649).toInt32());
  Expect.equals(new int32.fromInt(2147483646),
      new int64.fromInt(-2147483650).toInt32());
  Expect.equals(new int32.fromInt(2147483645),
      new int64.fromInt(-2147483651).toInt32());
}

void testDiv() {
  int64 deadBeef = new int64.fromInts(0xDEADBEEF, 0xDEADBEEF);
  int64 ten = new int64.fromInt(10);
  Expect.equals(new int64.fromInts(0xfcaaf97e, 0x63115fe5), deadBeef ~/ ten);
  Expect.equals(int64.ZERO, int64.ONE ~/ int64.TWO);
  Expect.equals(new int64.fromInts(0x3fffffff, 0xffffffff),
    int64.MAX_VALUE ~/ int64.TWO);
  
  Expect.equals(int64.ZERO, int64.ZERO ~/ new int64.fromInt(1000));
  Expect.equals(int64.ONE, int64.MIN_VALUE ~/ int64.MIN_VALUE);
  Expect.equals(int64.ZERO, new int64.fromInt(1000) ~/ int64.MIN_VALUE);

  Expect.equals("-1125899906842624",
    (int64.MIN_VALUE ~/ new int64.fromInt(8192)).toString());
  Expect.equals("-1125762484664320",
    (int64.MIN_VALUE ~/ new int64.fromInt(8193)).toString());
  Expect.equals(int64.ZERO,
    new int64.fromInt(-1000) ~/ new int64.fromInt(8192));
  Expect.equals(int64.ZERO,
    new int64.fromInt(-1000) ~/ new int64.fromInt(8193));
  Expect.equals(new int64.fromInt(-122070),
    new int64.fromInt(-1000000000) ~/ new int64.fromInt(8192));
  Expect.equals(new int64.fromInt(-122055),
    new int64.fromInt(-1000000000) ~/ new int64.fromInt(8193));
  Expect.equals(new int64.fromInt(122070),
    new int64.fromInt(1000000000) ~/ new int64.fromInt(8192));
  Expect.equals(new int64.fromInt(122055),
    new int64.fromInt(1000000000) ~/ new int64.fromInt(8193));
  
  Expect.equals(new int64.fromInts(0x1fffff, 0xffffffff),
    int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x00000400));
  Expect.equals(new int64.fromInts(0x1fff, 0xffffffff),
    int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x00040000));
  Expect.equals(new int64.fromInts(0x1f, 0xffffffff),
    int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x04000000));
  Expect.equals(new int64.fromInt(536870911),
    int64.MAX_VALUE ~/ new int64.fromInts(0x00000004, 0x00000000));
  Expect.equals(new int64.fromInt(2097151),
    int64.MAX_VALUE ~/ new int64.fromInts(0x00000400, 0x00000000));
  Expect.equals(new int64.fromInt(8191),
    int64.MAX_VALUE ~/ new int64.fromInts(0x00040000, 0x00000000));
  Expect.equals(new int64.fromInt(31),
    int64.MAX_VALUE ~/ new int64.fromInts(0x04000000, 0x00000000));
  
  Expect.equals(new int64.fromInts(0x2AAAAA, 0xAAAAAAAA),
      int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x00000300));
  Expect.equals(new int64.fromInts(0x2, 0xAAAAAAAA),
      int64.MAX_VALUE ~/ new int64.fromInts(0x00000000, 0x30000000));
  Expect.equals(new int64.fromInt(0x2AA),
      int64.MAX_VALUE ~/ new int64.fromInts(0x00300000, 0x00000000));

  Expect.equals(new int64.fromInts(0x708, 0x002E9501),
      int64.MAX_VALUE ~/ new int64.fromInt(0x123456));
  Expect.equals(new int64.fromInt(0x3BDA9),
      int64.MAX_VALUE % new int64.fromInt(0x123456));
}

void testFactorial() {

  int64 _fact(int64 n) {
    if (n.isZero()) {
      return new int64.fromInt(1);
    } else {
      return n * _fact(n - new int64.fromInt(1));
    }
  }

  int64 fact18 = _fact(new int64.fromInt(18));
  int64 fact17 = _fact(new int64.fromInt(17));
  Expect.equals(new int64.fromInt(18), fact18 ~/ fact17);
}

void testMinMax() {
  Expect.equals(int64.MIN_VALUE, new int64.fromInt(1) << 63);
  Expect.equals(int64.MAX_VALUE, -(int64.MIN_VALUE + new int64.fromInt(1)));
}

// Define % as Euclidean mod, with positive result for all arguments
void testMod() {
  Expect.equals(new int64.fromInt(0), int64.ZERO % new int64.fromInt(1000));
  Expect.equals(new int64.fromInt(0), int64.MIN_VALUE % int64.MIN_VALUE);
  Expect.equals(new int64.fromInt(1000),
    new int64.fromInt(1000) % int64.MIN_VALUE);
  Expect.equals(new int64.fromInt(0),
    int64.MIN_VALUE % new int64.fromInt(8192));
  Expect.equals(new int64.fromInt(6145),
    int64.MIN_VALUE % new int64.fromInt(8193));

  Expect.equals(new int64.fromInt(7192),
    new int64.fromInt(-1000) % new int64.fromInt(8192));
  Expect.equals(new int64.fromInt(7193),
    new int64.fromInt(-1000) % new int64.fromInt(8193));
  Expect.equals(new int64.fromInt(5632),
    new int64.fromInt(-1000000000) % new int64.fromInt(8192));
  Expect.equals(new int64.fromInt(4808),
    new int64.fromInt(-1000000000) % new int64.fromInt(8193));
  Expect.equals(new int64.fromInt(2560),
    new int64.fromInt(1000000000) % new int64.fromInt(8192));
  Expect.equals(new int64.fromInt(3385),
    new int64.fromInt(1000000000) % new int64.fromInt(8193));

  Expect.equals(new int64.fromInts(0x0, 0x3ff),
    int64.MAX_VALUE % new int64.fromInts(0x00000000, 0x00000400));
  Expect.equals(new int64.fromInts(0x0, 0x3ffff),
    int64.MAX_VALUE % new int64.fromInts(0x00000000, 0x00040000));
  Expect.equals(new int64.fromInts(0x0, 0x3ffffff),
    int64.MAX_VALUE % new int64.fromInts(0x00000000, 0x04000000));
  Expect.equals(new int64.fromInts(0x3, 0xffffffff),
    int64.MAX_VALUE % new int64.fromInts(0x00000004, 0x00000000));
  Expect.equals(new int64.fromInts(0x3ff, 0xffffffff),
    int64.MAX_VALUE % new int64.fromInts(0x00000400, 0x00000000));
  Expect.equals(new int64.fromInts(0x3ffff, 0xffffffff),
    int64.MAX_VALUE % new int64.fromInts(0x00040000, 0x00000000));
  Expect.equals(new int64.fromInts(0x3ffffff, 0xffffffff),
    int64.MAX_VALUE % new int64.fromInts(0x04000000, 0x00000000));

  Expect.equals(new int64.fromInt(0x12345678.remainder(0x22)),
      new int64.fromInt(0x12345678).remainder(new int64.fromInt(0x22)));
  Expect.equals(new int64.fromInt(0x12345678.remainder(-0x22)),
      new int64.fromInt(0x12345678).remainder(new int64.fromInt(-0x22)));
  Expect.equals(new int64.fromInt(-0x12345678.remainder(-0x22)),
      new int64.fromInt(-0x12345678).remainder(new int64.fromInt(-0x22)));
  Expect.equals(new int64.fromInt(-0x12345678.remainder(0x22)),
      new int64.fromInt(-0x12345678).remainder(new int64.fromInt(0x22)));
  Expect.equals(new int64.fromInt(0x12345678.remainder(0x22)),
      new int32.fromInt(0x12345678).remainder(new int64.fromInt(0x22)));
}

void testMultiplicative() {
  Expect.equals(new int64.fromInt(3333),
    new int64.fromInt(1111) * new int64.fromInt(3));
  Expect.equals(new int64.fromInt(-3333),
    new int64.fromInt(1111) * new int64.fromInt(-3));
  Expect.equals(new int64.fromInt(-3333),
    new int64.fromInt(-1111) * new int64.fromInt(3));
  Expect.equals(new int64.fromInt(3333),
    new int64.fromInt(-1111) * new int64.fromInt(-3));
  Expect.equals(new int64.fromInt(0),
    new int64.fromInt(100) * new int64.fromInt(0));

  Expect.equals(new int64.fromInts(0x7ff63f7c, 0x1df4d840), 
      new int64.fromInts(0x12345678, 0x12345678) *
      new int64.fromInts(0x1234, 0x12345678));
  Expect.equals(new int64.fromInts(0x7ff63f7c, 0x1df4d840), 
      new int64.fromInts(0xf2345678, 0x12345678) *
      new int64.fromInts(0x1234, 0x12345678));
  Expect.equals(new int64.fromInts(0x297e3f7c, 0x1df4d840), 
      new int64.fromInts(0xf2345678, 0x12345678) *
      new int64.fromInts(0xffff1234, 0x12345678));

  Expect.equals(new int64.fromInt(0), int64.MIN_VALUE * new int64.fromInt(2));
  Expect.equals(int64.MIN_VALUE, int64.MIN_VALUE * new int64.fromInt(1));
  Expect.equals(int64.MIN_VALUE, int64.MIN_VALUE * new int64.fromInt(-1));

  Expect.equals(new int64.fromInt(1), new int64.fromInt(5) ~/
      new int64.fromInt(5));
  Expect.equals(new int64.fromInt(333), new int64.fromInt(1000) ~/
      new int64.fromInt(3));
  Expect.equals(new int64.fromInt(-333), new int64.fromInt(1000) ~/
      new int64.fromInt(-3));
  Expect.equals(new int64.fromInt(-333), new int64.fromInt(-1000) ~/
      new int64.fromInt(3));
  Expect.equals(new int64.fromInt(333), new int64.fromInt(-1000) ~/
      new int64.fromInt(-3));
  Expect.equals(new int64.fromInt(0), new int64.fromInt(3) ~/
      new int64.fromInt(1000));
  Expect.equals(new int64.fromInts(0x1003d0, 0xe84f5ae8), new int64.fromInts(
      0x12345678, 0x12345678) ~/ new int64.fromInts(0x0, 0x123));
  Expect.equals(new int64.fromInts(0x0, 0x10003), new int64.fromInts(
      0x12345678, 0x12345678) ~/ new int64.fromInts(0x1234, 0x12345678));
  Expect.equals(new int64.fromInts(0xffffffff, 0xffff3dfe), 
      new int64.fromInts(0xf2345678, 0x12345678) ~/
      new int64.fromInts(0x1234, 0x12345678));
  Expect.equals(new int64.fromInts(0x0, 0xeda), new int64.fromInts(0xf2345678,
      0x12345678) ~/ new int64.fromInts(0xffff1234, 0x12345678));

  try {
    new int64.fromInt(1) ~/ new int64.fromInt(0);
    Expect.fail("Expected an IntegerDivisionByZeroException");
  } catch (IntegerDivisionByZeroException e) {
  }

  Expect.equals(new int64.fromInts(0xc0000000, 0x00000000), 
      int64.MIN_VALUE ~/ new int64.fromInt(2));
  Expect.equals(int64.MIN_VALUE, int64.MIN_VALUE ~/
      new int64.fromInt(1));
  Expect.equals(int64.MIN_VALUE, int64.MIN_VALUE ~/
      new int64.fromInt(-1));
}

void testNegate() {
  Expect.equals(new int64.fromInt(-1), -new int64.fromInt(1));
  Expect.equals(new int64.fromInt(1), -new int64.fromInt(-1));
  Expect.equals(int64.MIN_VALUE, -int64.MIN_VALUE);
}

void testShift() {
  Expect.equals("-1125899906842624", (int64.MIN_VALUE >> 13).toString());
  Expect.equals(new int64.fromInts(0xd048d115, 0x9d159c00),
    new int64.fromInts(0x12341234, 0x45674567) << 10);
  Expect.equals(new int64.fromInts(0x48d04, 0x8d1159d1),
    new int64.fromInts(0x12341234, 0x45674567) >> 10);
  Expect.equals(new int64.fromInts(0x48d04, 0x8d1159d1),
    new int64.fromInts(0x12341234, 0x45674567).shiftRightUnsigned(10));
  Expect.equals(new int64.fromInts(0xd048d115, 0x9d159c00),
    new int64.fromInts(0x92341234, 0x45674567) << 10);
  Expect.equals(new int64.fromInts(0xffe48d04, 0x8d1159d1),
    new int64.fromInts(0x92341234, 0x45674567) >> 10);
  Expect.equals(new int64.fromInt(67108863),
    new int64.fromInts(0xFFFFFFF, 0xFFFFFFFF) >> 34);
  Expect.equals(new int64.fromInts(0x248d04, 0x8d1159d1),
    new int64.fromInts(0x92341234, 0x45674567).shiftRightUnsigned(10));

  for (int n = 0; n <= 66; n++) {
    Expect.equals(new int64.fromInt(-1), new int64.fromInt(-1) >> n);
  }

  Expect.equals(new int64.fromInt(-1 << 5), new int64.fromInt(-1) << 5);
  Expect.equals(new int64.fromInt(-1), new int64.fromInt(-1) << 0);
  Expect.equals(-new int64.fromInts(0x40000000, 0x00000000),
    (new int64.fromInt(1) << 63) >> 1);
  Expect.equals(new int64.fromInt(0), (new int64.fromInt(-1) << 32) << 32);
  Expect.equals(int64.MIN_VALUE, int64.MIN_VALUE << 0);
  Expect.equals(new int64.fromInt(0), int64.MIN_VALUE << 1);
  Expect.equals(new int64.fromInts(0xfffffffc, 0x00000000),
    (-new int64.fromInts(8, 0)) >> 1);
  Expect.equals(new int64.fromInts(0x7ffffffc, 0x0),
    (-new int64.fromInts(8, 0)).shiftRightUnsigned(1));
  
  Expect.equals(new int64.fromInts(0x00723456, 0x789abcde),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 8);
  Expect.equals(new int64.fromInts(0x00007234, 0x56789abc),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 16);
  Expect.equals(new int64.fromInts(0x00000072, 0x3456789a),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 24);
  Expect.equals(new int64.fromInts(0x00000007, 0x23456789),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 28);
  Expect.equals(new int64.fromInts(0x00000000, 0x72345678),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 32);
  Expect.equals(new int64.fromInts(0x00000000, 0x07234567),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 36);
  Expect.equals(new int64.fromInts(0x00000000, 0x00723456),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 40);
  Expect.equals(new int64.fromInts(0x00000000, 0x00072345),
      new int64.fromInts(0x72345678, 0x9abcde00) >> 44);
  Expect.equals(new int64.fromInts(0x00000000, 0x00007234),
      new int64.fromInts(0x72345678, 0x9abcdef0) >> 48);

  Expect.equals(new int64.fromInts(0x00723456, 0x789abcde),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(8));
  Expect.equals(new int64.fromInts(0x00007234, 0x56789abc),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(16));
  Expect.equals(new int64.fromInts(0x00000072, 0x3456789a),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(24));
  Expect.equals(new int64.fromInts(0x00000007, 0x23456789),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(28));
  Expect.equals(new int64.fromInts(0x00000000, 0x72345678),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(32));
  Expect.equals(new int64.fromInts(0x00000000, 0x07234567),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(36));
  Expect.equals(new int64.fromInts(0x00000000, 0x00723456),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(40));
  Expect.equals(new int64.fromInts(0x00000000, 0x00072345),
      new int64.fromInts(0x72345678, 0x9abcde00).shiftRightUnsigned(44));
  Expect.equals(new int64.fromInts(0x00000000, 0x00007234),
      new int64.fromInts(0x72345678, 0x9abcdef0).shiftRightUnsigned(48));
  
  Expect.equals(new int64.fromInts(0xff923456, 0x789abcde),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 8);
  Expect.equals(new int64.fromInts(0xffff9234, 0x56789abc),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 16);

  Expect.equals(new int64.fromInts(0xffffff92, 0x3456789a),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 24);
  Expect.equals(new int64.fromInts(0xfffffff9, 0x23456789),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 28);
  Expect.equals(new int64.fromInts(0xffffffff, 0x92345678),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 32);
  Expect.equals(new int64.fromInts(0xffffffff, 0xf9234567),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 36);
  Expect.equals(new int64.fromInts(0xffffffff, 0xff923456),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 40);
  Expect.equals(new int64.fromInts(0xffffffff, 0xfff92345),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 44);
  Expect.equals(new int64.fromInts(0xffffffff, 0xffff9234),
      new int64.fromInts(0x92345678, 0x9abcdef0) >> 48);

  Expect.equals(new int64.fromInts(0x00923456, 0x789abcde),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(8));
  Expect.equals(new int64.fromInts(0x00009234, 0x56789abc),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(16));
  Expect.equals(new int64.fromInts(0x00000092, 0x3456789a),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(24));
  Expect.equals(new int64.fromInts(0x00000009, 0x23456789),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(28));
  Expect.equals(new int64.fromInts(0x00000000, 0x92345678),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(32));
  Expect.equals(new int64.fromInts(0x00000000, 0x09234567),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(36));
  Expect.equals(new int64.fromInts(0x00000000, 0x00923456),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(40));
  Expect.equals(new int64.fromInts(0x00000000, 0x00092345),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(44));
  Expect.equals(new int64.fromInts(0x00000000, 0x00009234),
      new int64.fromInts(0x92345678, 0x9abcdef0).shiftRightUnsigned(48));

  try {
    new int64.fromInt(17) >> -1;
    Expect.fail("x >> -1 should throw IllegalArgumentException");
  } catch (IllegalArgumentException e) {
  }

  try {
    new int64.fromInt(17) << -1;
    Expect.fail("x >> -1 should throw IllegalArgumentException");
  } catch (IllegalArgumentException e) {
  }

  try {
    new int64.fromInt(17).shiftRightUnsigned(-1);
    Expect.fail("x >> -1 should throw IllegalArgumentException");
  } catch (IllegalArgumentException e) {
  }

}

void testToHexString() {
  int64 deadbeef12341234 = new int64.fromInts(0xDEADBEEF, 0x12341234);
  Expect.equals("0", int64.ZERO.toHexString());
  Expect.equals("DEADBEEF12341234", deadbeef12341234.toHexString());
}

void testToString() {
  Expect.equals("0", new int64.fromInt(0).toString());
  Expect.equals("1", new int64.fromInt(1).toString());
  Expect.equals("-1", new int64.fromInt(-1).toString());
  Expect.equals("-10", new int64.fromInt(-10).toString());
  Expect.equals("-9223372036854775808", int64.MIN_VALUE.toString());
  Expect.equals("9223372036854775807", int64.MAX_VALUE.toString());

  int top = 922337201;
  int bottom = 967490662;
  int64 fullnum = (new int64.fromInt(1000000000) * new int64.fromInt(top)) +
      new int64.fromInt(bottom);

  Expect.equals("922337201967490662", fullnum.toString());
  Expect.equals("-922337201967490662", (-fullnum).toString());

  Expect.equals("17678A7DEF01234",
      new int64.fromInts(0x17678A7, 0xDEF01234).toHexString());

  Expect.equals("123456789", new int64.fromInt(123456789).toString());
  Expect.equals("75BCD15", new int64.fromInt(123456789).toHexString());
  Expect.equals("223101104124", new int64.fromInt(123456789).toRadixString(5));

  Expect.equals(
        "-1000000000000000000000000000000000000000000000000000000000000000",
      int64.MIN_VALUE.toRadixString(2));
  Expect.equals("-2021110011022210012102010021220101220222",
      int64.MIN_VALUE.toRadixString(3));
  Expect.equals("-20000000000000000000000000000000",
      int64.MIN_VALUE.toRadixString(4));
  Expect.equals("-1104332401304422434310311213",
      int64.MIN_VALUE.toRadixString(5));
  Expect.equals("-1540241003031030222122212", int64.MIN_VALUE.toRadixString(6));
  Expect.equals("-22341010611245052052301", int64.MIN_VALUE.toRadixString(7));
  Expect.equals("-1000000000000000000000", int64.MIN_VALUE.toRadixString(8));
  Expect.equals("-67404283172107811828", int64.MIN_VALUE.toRadixString(9));
  Expect.equals("-9223372036854775808", int64.MIN_VALUE.toRadixString(10));
  Expect.equals("-1728002635214590698", int64.MIN_VALUE.toRadixString(11));
  Expect.equals("-41A792678515120368", int64.MIN_VALUE.toRadixString(12));
  Expect.equals("-10B269549075433C38", int64.MIN_VALUE.toRadixString(13));
  Expect.equals("-4340724C6C71DC7A8", int64.MIN_VALUE.toRadixString(14));
  Expect.equals("-160E2AD3246366808", int64.MIN_VALUE.toRadixString(15));
  Expect.equals("-8000000000000000", int64.MIN_VALUE.toRadixString(16));

  Expect.equals(
        "111111111111111111111111111111111111111111111111111111111111111",
      int64.MAX_VALUE.toRadixString(2));
  Expect.equals("2021110011022210012102010021220101220221",
      int64.MAX_VALUE.toRadixString(3));
  Expect.equals("13333333333333333333333333333333",
      int64.MAX_VALUE.toRadixString(4));
  Expect.equals("1104332401304422434310311212",
      int64.MAX_VALUE.toRadixString(5));
  Expect.equals("1540241003031030222122211", int64.MAX_VALUE.toRadixString(6));
  Expect.equals("22341010611245052052300", int64.MAX_VALUE.toRadixString(7));
  Expect.equals("777777777777777777777", int64.MAX_VALUE.toRadixString(8));
  Expect.equals("67404283172107811827", int64.MAX_VALUE.toRadixString(9));
  Expect.equals("9223372036854775807", int64.MAX_VALUE.toRadixString(10));
  Expect.equals("1728002635214590697", int64.MAX_VALUE.toRadixString(11));
  Expect.equals("41A792678515120367", int64.MAX_VALUE.toRadixString(12));
  Expect.equals("10B269549075433C37", int64.MAX_VALUE.toRadixString(13));
  Expect.equals("4340724C6C71DC7A7", int64.MAX_VALUE.toRadixString(14));
  Expect.equals("160E2AD3246366807", int64.MAX_VALUE.toRadixString(15));
  Expect.equals("7FFFFFFFFFFFFFFF", int64.MAX_VALUE.toRadixString(16));
}
