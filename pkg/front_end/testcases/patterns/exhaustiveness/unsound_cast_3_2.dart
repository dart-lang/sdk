// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.2

// This exercises unsound code in version <= 3.2.

sealed class S {}

class A extends S {}

class B extends S {}

class C extends S {}

class X extends A {}

class Y extends B {}

class Z implements A, B {}

int unsound1(S s) => switch (s) {
      X() as A => 0,
      Y() as B => 1,
    };

int? sound1(S s) => switch (s) {
      X() as A => 0,
      Y() as B => 1,
      _ => null,
    };

int unsound2(S s) {
  switch (s) {
    case X() as A:
      return 0;
    case Y() as B:
      return 1;
  }
}

int? sound2(S s) {
  switch (s) {
    case X() as A:
      return 0;
    case Y() as B:
      return 1;
    case _:
      return null;
  }
}

main() {
  expect(sound1(X()), unsound1(X()));
  throws(() => unsound1(Z()));

  expect(sound2(X()), unsound2(X()));
  throws(() => unsound2(Z()));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}

throws(void Function() f) {
  try {
    f();
  } catch (e) {
    print(e);
    return;
  }
  throw 'Missing exception';
}
