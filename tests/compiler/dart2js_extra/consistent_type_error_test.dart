// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type checks give consistent errors for the same types. In minified
// mode this checks that the minified class names are consistently tagged.

import 'package:expect/expect.dart';

class Plain {}

class Foo<U> {}

class Test<T> {
  @pragma('dart2js:noInline')
  asT(o) => o as T;

  @pragma('dart2js:noInline')
  asFooT(o) => o as Foo<T>;

  @pragma('dart2js:noInline')
  testT(o) {
    T result = o;
  }

  @pragma('dart2js:noInline')
  testFooT(o) {
    Foo<T> result = o;
  }
}

capture(action()) {
  try {
    action();
  } catch (e) {
    print('$e');
    return '$e';
  }
  Expect.fail('Action should have failed');
}

dynamic g;

casts() {
  g = Foo<String>();

  Expect.equals(
    capture(() => Test<Foo<Plain>>().asT(g)),
    capture(() => g as Foo<Plain>),
    "C1",
  );

  Expect.equals(
    capture(() => g as Foo<Plain>),
    capture(() => Test<Plain>().asFooT(g)),
    "C2",
  );

  Expect.equals(
    capture(() => Test<Plain>().asT(g)),
    capture(() => g as Plain),
    "C3",
  );

  g = Foo<Plain>();

  Expect.equals(
    capture(() => Test<Foo<String>>().asT(g)),
    capture(() => g as Foo<String>),
    "C4",
  );

  Expect.equals(
    capture(() => g as Foo<String>),
    capture(() => Test<String>().asFooT(g)),
    "C5",
  );

  g = Plain();

  Expect.equals(
    capture(() => Test<String>().asT(g)),
    capture(() => g as String),
    "C6",
  );

  Expect.equals(
    capture(() => Test<int>().asT(g)),
    capture(() => g as int),
    "C7",
  );

  Expect.equals(
    capture(() => Test<double>().asT(g)),
    capture(() => g as double),
    "C8",
  );

  Expect.equals(
    capture(() => Test<bool>().asT(g)),
    capture(() => g as bool),
    "C9",
  );

  Expect.equals(
    capture(() => Test<List>().asT(g)),
    capture(() => g as List),
    "C10",
  );
}

tests() {
  g = Foo<String>();

  Expect.equals(
    capture(() => Test<Foo<Plain>>().testT(g)),
    capture(() {
      Foo<Plain> x = g;
    }),
    "T1",
  );

  Expect.equals(
    capture(() {
      Foo<Plain> x = g;
    }),
    capture(() => Test<Plain>().testFooT(g)),
    "T2",
  );

  Expect.equals(
    capture(() => Test<Plain>().testT(g)),
    capture(() {
      Plain x = g;
    }),
    "T3",
  );

  g = Foo<Plain>();

  Expect.equals(
    capture(() => Test<Foo<String>>().testT(g)),
    capture(() {
      Foo<String> x = g;
    }),
    "T4",
  );

  Expect.equals(
    capture(() {
      Foo<String> x = g;
    }),
    capture(() => Test<String>().testFooT(g)),
    "T5",
  );

  g = Plain();

  Expect.equals(
    capture(() => Test<String>().testT(g)),
    capture(() {
      String x = g;
    }),
    "T6",
  );

  Expect.equals(
    capture(() => Test<int>().testT(g)),
    capture(() {
      int x = g;
    }),
    "T7",
  );

  Expect.equals(
    capture(() => Test<double>().testT(g)),
    capture(() {
      double x = g;
    }),
    "T8",
  );

  Expect.equals(
    capture(() => Test<bool>().testT(g)),
    capture(() {
      bool x = g;
    }),
    "T9",
  );

  Expect.equals(
    capture(() => Test<List>().testT(g)),
    capture(() {
      List x = g;
    }),
    "T10",
  );
}

main() {
  casts();
  tests();
}
