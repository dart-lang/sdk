// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library enumset.test;

import 'package:compiler/src/util/enumset.dart';
import 'package:expect/expect.dart';

enum Enum {
  A,
  B,
  C,
  D,
  E,
  F,
}

main() {
  testAddRemoveContains();
  testConstructorsIntersects();
}

void checkEnumSet(
    EnumSet<Enum> enumSet, int expectedValue, List<Enum> expectedValues) {
  Expect.equals(expectedValue, enumSet.mask,
      "Unexpected EnumSet.value for ${enumSet.iterable(Enum.values)}");
  Expect.listEquals(expectedValues, enumSet.iterable(Enum.values).toList(),
      "Unexpected values: ${enumSet.iterable(Enum.values)}");
  Expect.equals(expectedValues.isEmpty, enumSet.isEmpty,
      "Unexpected EnumSet.isEmpty for ${enumSet.iterable(Enum.values)}");
  for (Enum value in Enum.values) {
    Expect.equals(
        expectedValues.contains(value),
        enumSet.contains(value),
        "Unexpected EnumSet.contains for $value in "
        "${enumSet.iterable(Enum.values)}");
  }
}

void testAddRemoveContains() {
  EnumSet<Enum> enumSet = EnumSet<Enum>.empty();

  void check(int expectedValue, List<Enum> expectedValues) {
    checkEnumSet(enumSet, expectedValue, expectedValues);
  }

  check(0, []);

  enumSet += Enum.B;
  check(2, [Enum.B]);

  enumSet += Enum.F;
  check(34, [Enum.F, Enum.B]);

  enumSet += Enum.A;
  check(35, [Enum.F, Enum.B, Enum.A]);

  enumSet += Enum.A;
  check(35, [Enum.F, Enum.B, Enum.A]);

  enumSet -= Enum.C;
  check(35, [Enum.F, Enum.B, Enum.A]);

  enumSet -= Enum.B;
  check(33, [Enum.F, Enum.A]);

  enumSet -= Enum.A;
  check(32, [Enum.F]);

  enumSet = EnumSet.empty();
  check(0, []);

  enumSet += Enum.A;
  enumSet += Enum.B;
  enumSet += Enum.C;
  enumSet += Enum.D;
  enumSet += Enum.E;
  enumSet += Enum.F;
  check(63, [Enum.F, Enum.E, Enum.D, Enum.C, Enum.B, Enum.A]);
}

void testConstructorsIntersects() {
  EnumSet<Enum> emptyA = EnumSet<Enum>.empty();
  EnumSet<Enum> emptyB = EnumSet<Enum>(0);
  EnumSet<Enum> emptyC = const EnumSet<Enum>.empty();
  EnumSet<Enum> emptyD = const EnumSet<Enum>(0);
  EnumSet<Enum> emptyE = EnumSet<Enum>.fromValues(const []);

  void checkIntersects(EnumSet<Enum> a, EnumSet<Enum> b, bool expectedValue) {
    Expect.equals(
        expectedValue, a.intersects(b), "Unexpected intersects of $a and $b");
    Expect.equals(a.intersects(b), b.intersects(a),
        "Unsymmetric intersects of $a and $b");
  }

  void check(EnumSet<Enum> a, EnumSet<Enum> b) {
    Expect.equals(a.mask, b.mask, "Unexpected values of $a and $b");
    Expect.equals(a.hashCode, b.hashCode, "Unexpected hash codes of $a and $b");
    Expect.equals(a, b, "Unexpected equality of $a and $b");
    checkIntersects(a, b, !a.isEmpty);
  }

  check(emptyA, emptyA);
  check(emptyA, emptyB);
  check(emptyA, emptyC);
  check(emptyA, emptyD);
  check(emptyA, emptyE);

  EnumSet<Enum> singleA = const EnumSet<Enum>.empty() + Enum.C;
  EnumSet<Enum> singleB = EnumSet<Enum>.empty() + Enum.C;
  EnumSet<Enum> singleC = const EnumSet<Enum>(4);
  EnumSet<Enum> singleD = EnumSet<Enum>(4);
  EnumSet<Enum> singleE = EnumSet<Enum>.fromValues([Enum.C]);
  EnumSet<Enum> singleF = EnumSet<Enum>.fromValue(Enum.C);

  check(singleA, singleA);
  check(singleA, singleB);
  check(singleA, singleC);
  check(singleA, singleD);
  check(singleA, singleE);
  check(singleA, singleF);

  EnumSet<Enum> multiA = const EnumSet<Enum>.empty() + Enum.A + Enum.D + Enum.F;
  EnumSet<Enum> multiB = EnumSet<Enum>.empty() + Enum.A + Enum.D + Enum.F;
  EnumSet<Enum> multiC = const EnumSet<Enum>(41);
  EnumSet<Enum> multiD = EnumSet<Enum>(41);
  EnumSet<Enum> multiE = EnumSet<Enum>.fromValues([Enum.F, Enum.A, Enum.D]);

  check(multiA, multiA);
  check(multiA, multiB);
  check(multiA, multiC);
  check(multiA, multiD);
  check(multiA, multiE);

  EnumSet<Enum> multi2 = EnumSet<Enum>.fromValues([Enum.F, Enum.A, Enum.C]);

  checkIntersects(emptyA, singleA, false);
  checkIntersects(emptyA, multiA, false);
  checkIntersects(emptyA, multi2, false);

  checkIntersects(singleA, multiA, false);
  checkIntersects(singleA, multi2, true);

  checkIntersects(multiA, multi2, true);
}
