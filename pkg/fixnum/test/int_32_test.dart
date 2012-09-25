// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("int32test");
#import('../fixnum.dart');

void main() {
  Expect.equals("0", new int32.fromInt(0).toString());
  Expect.equals("1", new int32.fromInt(1).toString());
  Expect.equals("-1", new int32.fromInt(-1).toString());
  Expect.equals("1000", new int32.fromInt(1000).toString());
  Expect.equals("-1000", new int32.fromInt(-1000).toString());
  Expect.equals("2147483647", new int32.fromInt(2147483647).toString());
  Expect.equals("-2147483648", new int32.fromInt(2147483648).toString());
  Expect.equals("-2147483647", new int32.fromInt(2147483649).toString());
  Expect.equals("-2147483646", new int32.fromInt(2147483650).toString());
  Expect.equals("-2147483648", new int32.fromInt(-2147483648).toString());
  Expect.equals("2147483647", new int32.fromInt(-2147483649).toString());
  Expect.equals("2147483646",  new int32.fromInt(-2147483650).toString());

  Expect.equals("-1", new int32.fromInt(-1).toHexString());
  Expect.equals("-1", (new int32.fromInt(-1) >> 8).toHexString());
  Expect.equals("-100", (new int32.fromInt(-1) << 8).toHexString());
  Expect.equals("ffffff",
      new int32.fromInt(-1).shiftRightUnsigned(8).toHexString());

  Expect.equals("123456789", new int32.fromInt(123456789).toString());
  Expect.equals("75bcd15", new int32.fromInt(123456789).toHexString());
  Expect.equals("223101104124", new int32.fromInt(123456789).toRadixString(5));

  try {
    new int32.fromInt(17) >> -1;
    Expect.fail("x >> -1 should throw ArgumentError");
  } on ArgumentError catch (e) {
  }

  try {
    new int32.fromInt(17) << -1;
    Expect.fail("x >> -1 should throw ArgumentError");
  } on ArgumentError catch (e) {
  }

  try {
    new int32.fromInt(17).shiftRightUnsigned(-1);
    Expect.fail("x >> -1 should throw ArgumentError");
  } on ArgumentError catch (e) {
  }

  // wraparound
  Expect.equals("-67153019", (new int32.fromInt(123456789) *
      new int32.fromInt(987654321)).toString());
  Expect.equals("121932631112635269", (new int64.fromInt(123456789) *
      new int32.fromInt(987654321)).toString());
  Expect.equals("121932631112635269", (new int32.fromInt(123456789) *
      new int64.fromInt(987654321)).toString());
  Expect.equals("121932631112635269", (new int64.fromInt(123456789) *
      new int64.fromInt(987654321)).toString());

  Expect.equals("432461",
      (new int32.fromInt(829893893) ~/ new int32.fromInt(1919)).toString());
  Expect.equals("432461",
      (new int32.fromInt(829893893) ~/ new int64.fromInt(1919)).toString());
  Expect.equals("432461",
      (new int64.fromInt(829893893) ~/ new int32.fromInt(1919)).toString());
  Expect.equals("432461",
      (new int64.fromInt(829893893) ~/ new int64.fromInt(1919)).toString());
  Expect.equals("432461",
      (new int32.fromInt(829893893) ~/ 1919).toString());
  Expect.equals("432461",
      (new int64.fromInt(829893893) ~/ 1919).toString());

  Expect.isTrue(new int32.fromInt(12345) == 12345);
  Expect.isTrue(new int32.fromInt(12345) == new int32.fromInt(12345));
  Expect.isTrue(new int64.fromInt(12345) == new int32.fromInt(12345));

  Expect.equals(new int32.fromInt(~0x12345678),
      ~(new int32.fromInt(0x12345678)));
  Expect.equals(new int64.fromInt(-0x12345678),
      -(new int32.fromInt(0x12345678)));

  Expect.equals(new int32.fromInt(0x12345678 & 0x22222222),
      new int32.fromInt(0x12345678) & new int32.fromInt(0x22222222));
  Expect.equals(new int64.fromInt(0x12345678 & 0x22222222),
      new int32.fromInt(0x12345678) & new int64.fromInt(0x22222222));
  Expect.equals(new int32.fromInt(0x12345678 | 0x22222222),
      new int32.fromInt(0x12345678) | new int32.fromInt(0x22222222));
  Expect.equals(new int64.fromInt(0x12345678 | 0x22222222),
      new int32.fromInt(0x12345678) | new int64.fromInt(0x22222222));
  Expect.equals(new int32.fromInt(0x12345678 ^ 0x22222222),
      new int32.fromInt(0x12345678) ^ new int32.fromInt(0x22222222));
  Expect.equals(new int64.fromInt(0x12345678 ^ 0x22222222),
      new int32.fromInt(0x12345678) ^ new int64.fromInt(0x22222222));

  Expect.equals(new int32.fromInt(0x12345678 + 0x22222222),
      new int32.fromInt(0x12345678) + new int32.fromInt(0x22222222));
  Expect.equals(new int64.fromInt(0x12345678 + 0x22222222),
     new int32.fromInt(0x12345678) + new int64.fromInt(0x22222222));
  Expect.equals(new int32.fromInt(0x12345678 - 0x22222222),
     new int32.fromInt(0x12345678) - new int32.fromInt(0x22222222));
  Expect.equals(new int64.fromInt(0x12345678 - 0x22222222),
     new int32.fromInt(0x12345678) - new int64.fromInt(0x22222222));
  Expect.equals(new int32.fromInt(-899716112),
      new int32.fromInt(0x12345678) * new int32.fromInt(0x22222222));
  Expect.equals(new int64.fromInts(0x026D60DC, 0xCA5F6BF0),
      new int32.fromInt(0x12345678) * new int64.fromInt(0x22222222));
  Expect.equals(new int32.fromInt(0x12345678 % 0x22),
      new int32.fromInt(0x12345678) % new int32.fromInt(0x22));
  Expect.equals(new int32.fromInt(0x12345678 % 0x22),
      new int32.fromInt(0x12345678) % new int64.fromInt(0x22));
  Expect.equals(new int32.fromInt(0x12345678.remainder(0x22)),
      new int32.fromInt(0x12345678).remainder(new int32.fromInt(0x22)));
  Expect.equals(new int32.fromInt(0x12345678.remainder(-0x22)),
      new int32.fromInt(0x12345678).remainder(new int32.fromInt(-0x22)));
  Expect.equals(new int32.fromInt(-0x12345678.remainder(-0x22)),
      new int32.fromInt(-0x12345678).remainder(new int32.fromInt(-0x22)));
  Expect.equals(new int32.fromInt(-0x12345678.remainder(0x22)),
      new int32.fromInt(-0x12345678).remainder(new int32.fromInt(0x22)));
  Expect.equals(new int32.fromInt(0x12345678.remainder(0x22)),
      new int32.fromInt(0x12345678).remainder(new int64.fromInt(0x22)));
  Expect.equals(new int32.fromInt(0x12345678 ~/ 0x22),
      new int32.fromInt(0x12345678) ~/ new int32.fromInt(0x22));
  Expect.equals(new int32.fromInt(0x12345678 ~/ 0x22),
      new int32.fromInt(0x12345678) ~/ new int64.fromInt(0x22));

  Expect.equals(new int32.fromInt(0x12345678 >> 7),
      new int32.fromInt(0x12345678) >> 7);
  Expect.equals(new int32.fromInt(0x12345678 << 7),
      new int32.fromInt(0x12345678) << 7);
  Expect.equals(new int32.fromInt(0x12345678 >> 7),
      new int32.fromInt(0x12345678).shiftRightUnsigned(7));

  try {
    new int32.fromInt(17) < null;
    Expect.fail("x < null should throw NullPointerException");
  } on NullPointerException catch (e) {
  }

  try {
    new int32.fromInt(17) <= null;
    Expect.fail("x <= null should throw NullPointerException");
  } on NullPointerException catch (e) {
  }

  try {
    new int32.fromInt(17) > null;
    Expect.fail("x > null should throw NullPointerException");
  } on NullPointerException catch (e) {
  }

  try {
    new int32.fromInt(17) < null;
    Expect.fail("x >= null should throw NullPointerException");
  } on NullPointerException catch (e) {
  }

  Expect.isFalse(new int32.fromInt(17) == null);
}
