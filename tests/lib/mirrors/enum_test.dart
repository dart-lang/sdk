// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.enums;

import 'dart:mirrors';
import 'package:expect/expect.dart';
import 'stringify.dart';

class C {}

enum Suite { CLUBS, DIAMONDS, SPADES, HEARTS }

void main() {
  Expect.isFalse(reflectClass(C).isEnum);

  Expect.isTrue(reflectClass(Suite).isEnum);
  Expect.isFalse(reflectClass(Suite).isAbstract);
  var constructors = reflectClass(Suite).declarations.values
      .whereType<MethodMirror>()
      .where((d) => d.isConstructor)
      .toList();
  Expect.equals(1, constructors.length);
  Expect.throwsUnsupportedError(
    () => reflectClass(Suite).newInstance(Symbol.empty, [2, "BANANA"]),
  );

  Expect.equals(
    reflectClass(Suite),
    (reflectClass(C).owner as LibraryMirror).declarations[#Suite],
    "found in library",
  );

  Expect.equals(reflectClass(Suite), reflect(Suite.CLUBS).type);

  Expect.equals(0, reflect(Suite.CLUBS).getField(#index).reflectee);
  Expect.equals(1, reflect(Suite.DIAMONDS).getField(#index).reflectee);
  Expect.equals(2, reflect(Suite.SPADES).getField(#index).reflectee);
  Expect.equals(3, reflect(Suite.HEARTS).getField(#index).reflectee);

  Expect.equals(
    "Suite.CLUBS",
    reflect(Suite.CLUBS).invoke(#toString, []).reflectee,
  );
  Expect.equals(
    "Suite.DIAMONDS",
    reflect(Suite.DIAMONDS).invoke(#toString, []).reflectee,
  );
  Expect.equals(
    "Suite.SPADES",
    reflect(Suite.SPADES).invoke(#toString, []).reflectee,
  );
  Expect.equals(
    "Suite.HEARTS",
    reflect(Suite.HEARTS).invoke(#toString, []).reflectee,
  );

  Expect.setEquals(
    [
      'Variable(s(CLUBS) in s(Suite), static, final, const)',
      'Variable(s(DIAMONDS) in s(Suite), static, final, const)',
      'Variable(s(SPADES) in s(Suite), static, final, const)',
      'Variable(s(HEARTS) in s(Suite), static, final, const)',
      'Variable(s(values) in s(Suite), static, final, const)',
      'Method(s(Suite) in s(Suite), constructor)',
    ],
    reflectClass(
      Suite,
    ).declarations.values.where((d) => !d.isPrivate).map(stringify),
  );
}
