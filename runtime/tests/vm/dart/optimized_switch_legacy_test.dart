// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.19

// Test switches that use binary search or a jump table to dispatch cases.
// This legacy version of the test uses non-exhaustive switches
// which were allowed before Dart 3.0.

import 'package:expect/expect.dart';

void main() {
  Expect.isTrue(duplicateEnum(L._0) == 0);
  Expect.isTrue(duplicateEnum(L._1) == 1);
  Expect.isTrue(duplicateEnum(L._2) == 2);
  Expect.isTrue(duplicateEnum(L._3) == null);

  Expect.isTrue(duplicateInt(0) == 0);
  Expect.isTrue(duplicateInt(1) == 1);
  Expect.isTrue(duplicateInt(2) == 2);
  Expect.isTrue(duplicateInt(3) == null);

  Expect.isTrue(nullableEnum(null) == -1);
  Expect.isTrue(nullableEnum(L._0) == 0);
  Expect.isTrue(nullableEnum(L._1) == 1);
  Expect.isTrue(nullableEnum(L._2) == 2);
  Expect.isTrue(nullableEnum(L._3) == null);

  Expect.isTrue(nullableInt(null) == -1);
  Expect.isTrue(nullableInt(-1) == null);
  Expect.isTrue(nullableInt(0) == 0);
  Expect.isTrue(nullableInt(1) == 1);
  Expect.isTrue(nullableInt(2) == 2);
  Expect.isTrue(nullableInt(3) == null);

  Expect.isTrue(binarySearchEnumExhaustive(S._0) == 0);
  Expect.isTrue(binarySearchEnumExhaustive(S._1) == 1);
  Expect.isTrue(binarySearchEnumExhaustive(S._2) == 2);

  Expect.isTrue(binarySearchEnumWithDefault(null) == null);
  Expect.isTrue(binarySearchEnumWithDefault(S._0) == 0);
  Expect.isTrue(binarySearchEnumWithDefault(S._1) == null);
  Expect.isTrue(binarySearchEnumWithDefault(S._2) == 2);

  Expect.isTrue(binarySearchEnumHole(S._0) == 0);
  Expect.isTrue(binarySearchEnumHole(S._1) == null);
  Expect.isTrue(binarySearchEnumHole(S._2) == 2);

  Expect.isTrue(binarySearchEnumNoLowerBound(S._0) == null);
  Expect.isTrue(binarySearchEnumNoLowerBound(S._1) == 1);
  Expect.isTrue(binarySearchEnumNoLowerBound(S._2) == 2);

  Expect.isTrue(binarySearchEnumNoUpperBound(S._0) == 0);
  Expect.isTrue(binarySearchEnumNoUpperBound(S._1) == 1);
  Expect.isTrue(binarySearchEnumNoUpperBound(S._2) == null);

  Expect.isTrue(binarySearchInt(-2) == null);
  Expect.isTrue(binarySearchInt(-1) == -1);
  Expect.isTrue(binarySearchInt(0) == 0);
  Expect.isTrue(binarySearchInt(1) == 1);
  Expect.isTrue(binarySearchInt(2) == null);

  Expect.isTrue(binarySearchIntWithDefault(null) == null);
  Expect.isTrue(binarySearchIntWithDefault(-1) == null);
  Expect.isTrue(binarySearchIntWithDefault(0) == 0);
  Expect.isTrue(binarySearchIntWithDefault(1) == null);
  Expect.isTrue(binarySearchIntWithDefault(2) == 2);
  Expect.isTrue(binarySearchIntWithDefault(3) == null);

  Expect.isTrue(jumpTableEnumExhaustive(L._0) == 0);
  Expect.isTrue(jumpTableEnumExhaustive(L._1) == 1);
  Expect.isTrue(jumpTableEnumExhaustive(L._2) == 2);
  Expect.isTrue(jumpTableEnumExhaustive(L._3) == 3);
  Expect.isTrue(jumpTableEnumExhaustive(L._4) == 4);
  Expect.isTrue(jumpTableEnumExhaustive(L._5) == 5);
  Expect.isTrue(jumpTableEnumExhaustive(L._6) == 6);
  Expect.isTrue(jumpTableEnumExhaustive(L._7) == 7);
  Expect.isTrue(jumpTableEnumExhaustive(L._8) == 8);
  Expect.isTrue(jumpTableEnumExhaustive(L._9) == 9);
  Expect.isTrue(jumpTableEnumExhaustive(L._10) == 10);
  Expect.isTrue(jumpTableEnumExhaustive(L._11) == 11);
  Expect.isTrue(jumpTableEnumExhaustive(L._12) == 12);
  Expect.isTrue(jumpTableEnumExhaustive(L._13) == 13);
  Expect.isTrue(jumpTableEnumExhaustive(L._14) == 14);
  Expect.isTrue(jumpTableEnumExhaustive(L._15) == 15);
  Expect.isTrue(jumpTableEnumExhaustive(L._16) == 16);

  Expect.isTrue(jumpTableEnumWithDefault(null) == null);
  Expect.isTrue(jumpTableEnumWithDefault(L._0) == 0);
  Expect.isTrue(jumpTableEnumWithDefault(L._1) == 1);
  Expect.isTrue(jumpTableEnumWithDefault(L._2) == 2);
  Expect.isTrue(jumpTableEnumWithDefault(L._3) == 3);
  Expect.isTrue(jumpTableEnumWithDefault(L._4) == 4);
  Expect.isTrue(jumpTableEnumWithDefault(L._5) == 5);
  Expect.isTrue(jumpTableEnumWithDefault(L._6) == 6);
  Expect.isTrue(jumpTableEnumWithDefault(L._7) == 7);
  Expect.isTrue(jumpTableEnumWithDefault(L._8) == null);
  Expect.isTrue(jumpTableEnumWithDefault(L._9) == 9);
  Expect.isTrue(jumpTableEnumWithDefault(L._10) == 10);
  Expect.isTrue(jumpTableEnumWithDefault(L._11) == 11);
  Expect.isTrue(jumpTableEnumWithDefault(L._12) == 12);
  Expect.isTrue(jumpTableEnumWithDefault(L._13) == 13);
  Expect.isTrue(jumpTableEnumWithDefault(L._14) == 14);
  Expect.isTrue(jumpTableEnumWithDefault(L._15) == 15);
  Expect.isTrue(jumpTableEnumWithDefault(L._16) == 16);

  Expect.isTrue(jumpTableEnumHole(L._0) == 0);
  Expect.isTrue(jumpTableEnumHole(L._1) == null);
  Expect.isTrue(jumpTableEnumHole(L._2) == 2);
  Expect.isTrue(jumpTableEnumHole(L._3) == 3);
  Expect.isTrue(jumpTableEnumHole(L._4) == 4);
  Expect.isTrue(jumpTableEnumHole(L._5) == 5);
  Expect.isTrue(jumpTableEnumHole(L._6) == 6);
  Expect.isTrue(jumpTableEnumHole(L._7) == 7);
  Expect.isTrue(jumpTableEnumHole(L._8) == 8);
  Expect.isTrue(jumpTableEnumHole(L._9) == 9);
  Expect.isTrue(jumpTableEnumHole(L._10) == 10);
  Expect.isTrue(jumpTableEnumHole(L._11) == 11);
  Expect.isTrue(jumpTableEnumHole(L._12) == 12);
  Expect.isTrue(jumpTableEnumHole(L._13) == 13);
  Expect.isTrue(jumpTableEnumHole(L._14) == 14);
  Expect.isTrue(jumpTableEnumHole(L._15) == 15);
  Expect.isTrue(jumpTableEnumHole(L._16) == 16);

  Expect.isTrue(jumpTableEnumNoLowerBound(L._0) == null);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._1) == 1);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._2) == 2);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._3) == 3);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._4) == 4);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._5) == 5);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._6) == 6);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._7) == 7);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._8) == 8);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._9) == 9);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._10) == 10);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._11) == 11);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._12) == 12);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._13) == 13);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._14) == 14);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._15) == 15);
  Expect.isTrue(jumpTableEnumNoLowerBound(L._16) == 16);

  Expect.isTrue(jumpTableEnumNoUpperBound(L._0) == 0);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._1) == 1);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._2) == 2);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._3) == 3);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._4) == 4);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._5) == 5);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._6) == 6);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._7) == 7);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._8) == 8);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._9) == 9);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._10) == 10);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._11) == 11);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._12) == 12);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._13) == 13);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._14) == 14);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._15) == 15);
  Expect.isTrue(jumpTableEnumNoUpperBound(L._16) == null);

  Expect.isTrue(jumpTableInt(-2) == null);
  Expect.isTrue(jumpTableInt(-1) == -1);
  Expect.isTrue(jumpTableInt(0) == 0);
  Expect.isTrue(jumpTableInt(1) == 1);
  Expect.isTrue(jumpTableInt(2) == 2);
  Expect.isTrue(jumpTableInt(3) == 3);
  Expect.isTrue(jumpTableInt(4) == 4);
  Expect.isTrue(jumpTableInt(5) == 5);
  Expect.isTrue(jumpTableInt(6) == 6);
  Expect.isTrue(jumpTableInt(7) == 7);
  Expect.isTrue(jumpTableInt(8) == 8);
  Expect.isTrue(jumpTableInt(9) == 9);
  Expect.isTrue(jumpTableInt(10) == 10);
  Expect.isTrue(jumpTableInt(11) == 11);
  Expect.isTrue(jumpTableInt(12) == 12);
  Expect.isTrue(jumpTableInt(13) == 13);
  Expect.isTrue(jumpTableInt(14) == 14);
  Expect.isTrue(jumpTableInt(15) == null);

  Expect.isTrue(jumpTableIntWithDefault(null) == null);
  Expect.isTrue(jumpTableIntWithDefault(-1) == null);
  Expect.isTrue(jumpTableIntWithDefault(0) == 0);
  Expect.isTrue(jumpTableIntWithDefault(1) == 1);
  Expect.isTrue(jumpTableIntWithDefault(2) == 2);
  Expect.isTrue(jumpTableIntWithDefault(3) == 3);
  Expect.isTrue(jumpTableIntWithDefault(4) == 4);
  Expect.isTrue(jumpTableIntWithDefault(5) == 5);
  Expect.isTrue(jumpTableIntWithDefault(6) == 6);
  Expect.isTrue(jumpTableIntWithDefault(7) == 7);
  Expect.isTrue(jumpTableIntWithDefault(8) == null);
  Expect.isTrue(jumpTableIntWithDefault(9) == 9);
  Expect.isTrue(jumpTableIntWithDefault(10) == 10);
  Expect.isTrue(jumpTableIntWithDefault(11) == 11);
  Expect.isTrue(jumpTableIntWithDefault(12) == 12);
  Expect.isTrue(jumpTableIntWithDefault(13) == 13);
  Expect.isTrue(jumpTableIntWithDefault(14) == 14);
  Expect.isTrue(jumpTableIntWithDefault(15) == 15);
  Expect.isTrue(jumpTableIntWithDefault(16) == 16);
  Expect.isTrue(jumpTableIntWithDefault(17) == null);
}

/// Small enum that is used to test binary search switches.
enum S {
  _0,
  _1,
  _2,
}

/// Large enum that is used to test jump table switches.
///
/// Must have enough values to trigger a jump table (currently 16) + 1 so
/// we can create a jump table switch that is not exhaustive.
enum L {
  _0,
  _1,
  _2,
  _3,
  _4,
  _5,
  _6,
  _7,
  _8,
  _9,
  _10,
  _11,
  _12,
  _13,
  _14,
  _15,
  _16,
}

int? duplicateEnum(L v) {
  switch (v) {
    case L._0:
      return 0;
    case L._1:
      return 1;
    case L._2:
      return 2;
    case L._1:
      return 3;
  }
}

int? duplicateInt(int v) {
  switch (v) {
    case 0:
      return 0;
    case 1:
      return 1;
    case 2:
      return 2;
    case 1:
      return 3;
  }
}

int? nullableEnum(L? v) {
  switch (v) {
    case null:
      return -1;
    case L._0:
      return 0;
    case L._1:
      return 1;
    case L._2:
      return 2;
  }
}

int? nullableInt(int? v) {
  switch (v) {
    case null:
      return -1;
    case 0:
      return 0;
    case 1:
      return 1;
    case 2:
      return 2;
  }
}

int binarySearchEnumExhaustive(S v) {
  switch (v) {
    case S._0:
      return 0;
    case S._1:
      return 1;
    case S._2:
      return 2;
  }
}

int? binarySearchEnumWithDefault(S? v) {
  switch (v) {
    case S._0:
      return 0;
    case S._2:
      return 2;
    default:
      return null;
  }
}

int? binarySearchEnumHole(S v) {
  switch (v) {
    case S._0:
      return 0;
    case S._2:
      return 2;
  }
}

int? binarySearchEnumNoLowerBound(S v) {
  switch (v) {
    case S._1:
      return 1;
    case S._2:
      return 2;
  }
}

int? binarySearchEnumNoUpperBound(S v) {
  switch (v) {
    case S._0:
      return 0;
    case S._1:
      return 1;
  }
}

int? binarySearchInt(int v) {
  switch (v) {
    case -1:
      return -1;
    case 0:
      return 0;
    case 1:
      return 1;
  }
}

int? binarySearchIntWithDefault(int? v) {
  switch (v) {
    case 0:
      return 0;
    case 2:
      return 2;
    default:
      return null;
  }
}

int jumpTableEnumExhaustive(L v) {
  switch (v) {
    case L._0:
      return 0;
    case L._1:
      return 1;
    case L._2:
      return 2;
    case L._3:
      return 3;
    case L._4:
      return 4;
    case L._5:
      return 5;
    case L._6:
      return 6;
    case L._7:
      return 7;
    case L._8:
      return 8;
    case L._9:
      return 9;
    case L._10:
      return 10;
    case L._11:
      return 11;
    case L._12:
      return 12;
    case L._13:
      return 13;
    case L._14:
      return 14;
    case L._15:
      return 15;
    case L._16:
      return 16;
  }
}

int? jumpTableEnumWithDefault(L? v) {
  switch (v) {
    case L._0:
      return 0;
    case L._1:
      return 1;
    case L._2:
      return 2;
    case L._3:
      return 3;
    case L._4:
      return 4;
    case L._5:
      return 5;
    case L._6:
      return 6;
    case L._7:
      return 7;
    case L._9:
      return 9;
    case L._10:
      return 10;
    case L._11:
      return 11;
    case L._12:
      return 12;
    case L._13:
      return 13;
    case L._14:
      return 14;
    case L._15:
      return 15;
    case L._16:
      return 16;
    default:
      return null;
  }
}

int? jumpTableEnumHole(L v) {
  switch (v) {
    case L._0:
      return 0;
    case L._2:
      return 2;
    case L._3:
      return 3;
    case L._4:
      return 4;
    case L._5:
      return 5;
    case L._6:
      return 6;
    case L._7:
      return 7;
    case L._8:
      return 8;
    case L._9:
      return 9;
    case L._10:
      return 10;
    case L._11:
      return 11;
    case L._12:
      return 12;
    case L._13:
      return 13;
    case L._14:
      return 14;
    case L._15:
      return 15;
    case L._16:
      return 16;
  }
}

int? jumpTableEnumNoLowerBound(L v) {
  switch (v) {
    case L._1:
      return 1;
    case L._2:
      return 2;
    case L._3:
      return 3;
    case L._4:
      return 4;
    case L._5:
      return 5;
    case L._6:
      return 6;
    case L._7:
      return 7;
    case L._8:
      return 8;
    case L._9:
      return 9;
    case L._10:
      return 10;
    case L._11:
      return 11;
    case L._12:
      return 12;
    case L._13:
      return 13;
    case L._14:
      return 14;
    case L._15:
      return 15;
    case L._16:
      return 16;
  }
}

int? jumpTableEnumNoUpperBound(L v) {
  switch (v) {
    case L._0:
      return 0;
    case L._1:
      return 1;
    case L._2:
      return 2;
    case L._3:
      return 3;
    case L._4:
      return 4;
    case L._5:
      return 5;
    case L._6:
      return 6;
    case L._7:
      return 7;
    case L._8:
      return 8;
    case L._9:
      return 9;
    case L._10:
      return 10;
    case L._11:
      return 11;
    case L._12:
      return 12;
    case L._13:
      return 13;
    case L._14:
      return 14;
    case L._15:
      return 15;
  }
}

int? jumpTableInt(int v) {
  switch (v) {
    case -1:
      return -1;
    case 0:
      return 0;
    case 1:
      return 1;
    case 2:
      return 2;
    case 3:
      return 3;
    case 4:
      return 4;
    case 5:
      return 5;
    case 6:
      return 6;
    case 7:
      return 7;
    case 8:
      return 8;
    case 9:
      return 9;
    case 10:
      return 10;
    case 11:
      return 11;
    case 12:
      return 12;
    case 13:
      return 13;
    case 14:
      return 14;
  }
}

int? jumpTableIntWithDefault(int? v) {
  switch (v) {
    case 0:
      return 0;
    case 1:
      return 1;
    case 2:
      return 2;
    case 3:
      return 3;
    case 4:
      return 4;
    case 5:
      return 5;
    case 6:
      return 6;
    case 7:
      return 7;
    case 9:
      return 9;
    case 10:
      return 10;
    case 11:
      return 11;
    case 12:
      return 12;
    case 13:
      return 13;
    case 14:
      return 14;
    case 15:
      return 15;
    case 16:
      return 16;
    default:
      return null;
  }
}
