// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This test tests that AOT compiler does not optimize away necessary
// type checks.

class A {
  int _addOneToArgument(int x) => x + 1;
}

abstract class G<T> {
  int _addOneToArgument(T x);
}

class B extends A implements G<int> {}

class C {
  int _addTwoToArgument(int x) => x + 2;
}

class D {
  int _addThreeToArgument(num x) {
    return 0;
  }
}

class E extends D {
  int _addThreeToArgument(covariant int x) {
    return x + 3;
  }
}

final arr = <Object>[
  new B(),
  new C(),
  new E(),
  new D(), // Just to confuse CHA
];

main() {
  final b = arr[0] as G<num>;

  Expect.equals(1, b._addOneToArgument(0));
  Expect.equals(0, b._addOneToArgument(-1));
  Expect.throws(() => b._addOneToArgument(1.1));

  final c = (arr[1] as C);
  final tornMethod = c._addTwoToArgument;
  Expect.equals(2, c._addTwoToArgument(0));
  Expect.equals(0, c._addTwoToArgument(-2));
  Expect.throws(() => (tornMethod as dynamic)(1.1));

  final e = (arr[2] as D);
  Expect.equals(3, e._addThreeToArgument(0));
  Expect.equals(0, e._addThreeToArgument(-3));
  Expect.throws(() => e._addThreeToArgument(1.1));
}
