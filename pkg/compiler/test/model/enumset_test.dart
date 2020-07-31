// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

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

void checkEnumSet(EnumSet<Enum> enumSet, int expectedValue,
    List<Enum> expectedValues, String expectedToString) {
  Expect.equals(expectedValue, enumSet.value,
      "Unexpected EnumSet.value for ${enumSet.iterable(Enum.values)}");
  Expect.listEquals(expectedValues, enumSet.iterable(Enum.values).toList(),
      "Unexpected values: ${enumSet.iterable(Enum.values)}");
  Expect.equals(expectedValues.isEmpty, enumSet.isEmpty,
      "Unexpected EnumSet.isEmpty for ${enumSet.iterable(Enum.values)}");
  Expect.equals(expectedToString, enumSet.toString(),
      "Unexpected EnumSet.toString for ${enumSet.iterable(Enum.values)}");
  for (Enum value in Enum.values) {
    Expect.equals(
        expectedValues.contains(value),
        enumSet.contains(value),
        "Unexpected EnumSet.contains for $value in "
        "${enumSet.iterable(Enum.values)}");
  }
}

void testAddRemoveContains() {
  EnumSet<Enum> enumSet = new EnumSet<Enum>();

  void check(
      int expectedValue, List<Enum> expectedValues, String expectedToString) {
    checkEnumSet(enumSet, expectedValue, expectedValues, expectedToString);
  }

  check(0, [], '0');

  enumSet.add(Enum.B);
  check(2, [Enum.B], '10');

  enumSet.add(Enum.F);
  check(34, [Enum.F, Enum.B], '100010');

  enumSet.add(Enum.A);
  check(35, [Enum.F, Enum.B, Enum.A], '100011');

  enumSet.add(Enum.A);
  check(35, [Enum.F, Enum.B, Enum.A], '100011');

  enumSet.remove(Enum.C);
  check(35, [Enum.F, Enum.B, Enum.A], '100011');

  enumSet.remove(Enum.B);
  check(33, [Enum.F, Enum.A], '100001');

  enumSet.remove(Enum.A);
  check(32, [Enum.F], '100000');

  enumSet.clear();
  check(0, [], '0');

  enumSet.add(Enum.A);
  enumSet.add(Enum.B);
  enumSet.add(Enum.C);
  enumSet.add(Enum.D);
  enumSet.add(Enum.E);
  enumSet.add(Enum.F);
  check(63, [Enum.F, Enum.E, Enum.D, Enum.C, Enum.B, Enum.A], '111111');
}

void testConstructorsIntersects() {
  EnumSet<Enum> emptyA = new EnumSet<Enum>();
  EnumSet<Enum> emptyB = new EnumSet<Enum>.fromValue(0);
  EnumSet<Enum> emptyC = const EnumSet<Enum>.fixed(0);
  EnumSet<Enum> emptyD = new EnumSet<Enum>.fixed(0);

  void checkIntersects(EnumSet<Enum> a, EnumSet<Enum> b, bool expectedValue) {
    Expect.equals(
        expectedValue, a.intersects(b), "Unexpected intersects of $a and $b");
    Expect.equals(a.intersects(b), b.intersects(a),
        "Unsymmetric intersects of $a and $b");
  }

  void check(EnumSet<Enum> a, EnumSet<Enum> b) {
    Expect.equals(a.value, b.value, "Unexpected values of $a and $b");
    Expect.equals(a.hashCode, b.hashCode, "Unexpected hash codes of $a and $b");
    Expect.equals(a, b, "Unexpected equality of $a and $b");
    checkIntersects(a, b, !a.isEmpty);
  }

  check(emptyA, emptyA);
  check(emptyA, emptyB);
  check(emptyA, emptyC);
  check(emptyA, emptyD);

  EnumSet<Enum> singleA = new EnumSet<Enum>()..add(Enum.C);
  EnumSet<Enum> singleB = new EnumSet<Enum>.fromValue(4);
  EnumSet<Enum> singleC = const EnumSet<Enum>.fixed(4);
  EnumSet<Enum> singleD = new EnumSet<Enum>.fixed(4);
  EnumSet<Enum> singleE = new EnumSet<Enum>.fromValues([Enum.C]);
  EnumSet<Enum> singleF = new EnumSet<Enum>.fromValues([Enum.C], fixed: true);

  check(singleA, singleA);
  check(singleA, singleB);
  check(singleA, singleC);
  check(singleA, singleD);
  check(singleA, singleE);
  check(singleA, singleF);

  EnumSet<Enum> multiA = new EnumSet<Enum>()
    ..add(Enum.A)
    ..add(Enum.D)
    ..add(Enum.F);
  EnumSet<Enum> multiB = new EnumSet<Enum>.fromValue(41);
  EnumSet<Enum> multiC = const EnumSet<Enum>.fixed(41);
  EnumSet<Enum> multiD = new EnumSet<Enum>.fixed(41);
  EnumSet<Enum> multiE = new EnumSet<Enum>.fromValues([Enum.F, Enum.A, Enum.D]);
  EnumSet<Enum> multiF =
      new EnumSet<Enum>.fromValues([Enum.F, Enum.A, Enum.D], fixed: true);

  check(multiA, multiA);
  check(multiA, multiB);
  check(multiA, multiC);
  check(multiA, multiD);
  check(multiA, multiE);
  check(multiA, multiF);

  EnumSet<Enum> multi2 = new EnumSet<Enum>.fromValues([Enum.F, Enum.A, Enum.C]);

  checkIntersects(emptyA, singleA, false);
  checkIntersects(emptyA, multiA, false);
  checkIntersects(emptyA, multi2, false);

  checkIntersects(singleA, multiA, false);
  checkIntersects(singleA, multi2, true);

  checkIntersects(multiA, multi2, true);
}
