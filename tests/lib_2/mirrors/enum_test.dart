// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.enums;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

class C {}

enum Suite { CLUBS, DIAMONDS, SPADES, HEARTS }

main() {
  Expect.isFalse(reflectClass(C).isEnum);

  Expect.isTrue(reflectClass(Suite).isEnum);
  Expect.isFalse(reflectClass(Suite).isAbstract);
  Expect.equals(
      0,
      reflectClass(Suite)
          .declarations
          .values
          .where((d) => d is MethodMirror && d.isConstructor)
          .length);

  Expect.equals(
      reflectClass(Suite),
      (reflectClass(C).owner as LibraryMirror).declarations[#Suite],
      "found in library");

  Expect.equals(reflectClass(Suite), reflect(Suite.CLUBS).type);

  Expect.equals(0, reflect(Suite.CLUBS).getField(#index).reflectee);
  Expect.equals(1, reflect(Suite.DIAMONDS).getField(#index).reflectee);
  Expect.equals(2, reflect(Suite.SPADES).getField(#index).reflectee);
  Expect.equals(3, reflect(Suite.HEARTS).getField(#index).reflectee);

  Expect.equals(
      "Suite.CLUBS", reflect(Suite.CLUBS).invoke(#toString, []).reflectee);
  Expect.equals("Suite.DIAMONDS",
      reflect(Suite.DIAMONDS).invoke(#toString, []).reflectee);
  Expect.equals(
      "Suite.SPADES", reflect(Suite.SPADES).invoke(#toString, []).reflectee);
  Expect.equals(
      "Suite.HEARTS", reflect(Suite.HEARTS).invoke(#toString, []).reflectee);

  Expect.setEquals(
      [
        'Variable(s(index) in s(Suite), final)',
        'Variable(s(CLUBS) in s(Suite), static, final)',
        'Variable(s(DIAMONDS) in s(Suite), static, final)',
        'Variable(s(SPADES) in s(Suite), static, final)',
        'Variable(s(HEARTS) in s(Suite), static, final)',
        'Variable(s(values) in s(Suite), static, final)',
        'Method(s(hashCode) in s(Suite), getter)',
        'Method(s(toString) in s(Suite))'
      ],
      reflectClass(Suite)
          .declarations
          .values
          .where((d) => !d.isPrivate)
          .map(stringify));
}
