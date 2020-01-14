// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart test for deeply nested generic types.

/** A natural number aka Peano number. */
abstract class N {
  N add1();
  N sub1();
}

/** Zero element. */
class Z implements N {
  Z();
  N add1() {
    return new S<Z>(this);
  }

  N sub1() {
    throw "Error: sub1(0)";
  }
}

/** Successor element. */
class S<K> implements N {
  N before;
  S(this.before);
  N add1() {
    return new S<S<K>>(this);
  }

  N sub1() {
    // It would be super cool if this could be "new K()".
    return before;
  }
}

N NFromInt(int x) {
  if (x == 0)
    return new Z();
  else
    return NFromInt(x - 1).add1();
}

int IntFromN(N x) {
  if (x is Z) return 0;
  if (x is S) return IntFromN(x.sub1()) + 1;
  throw "Error";
}

bool IsEven(N x) {
  if (x is Z) return true;
  if (x is S<Z>) return false;
  if (x is S<S>) return IsEven(x.sub1().sub1());
  throw "Error in IsEven";
}

main() {
  Expect.isTrue(NFromInt(0) is Z);
  Expect.isTrue(NFromInt(1) is S<Z>);
  Expect.isTrue(NFromInt(2) is S<S<Z>>);
  Expect.isTrue(NFromInt(3) is S<S<S<Z>>>);
  Expect.isTrue(NFromInt(10) is S<S<S<S<S<S<S<S<S<S<Z>>>>>>>>>>);

  // Negative tests.
  Expect.isTrue(NFromInt(0) is! S);
  Expect.isTrue(NFromInt(1) is! Z);
  Expect.isTrue(NFromInt(1) is! S<S>);
  Expect.isTrue(NFromInt(2) is! Z);
  Expect.isTrue(NFromInt(2) is! S<Z>);
  Expect.isTrue(NFromInt(2) is! S<S<S>>);

  // Greater-than tests
  Expect.isTrue(NFromInt(4) is S<S>); //            4 >= 2
  Expect.isTrue(NFromInt(4) is S<S<S>>); //         4 >= 3
  Expect.isTrue(NFromInt(4) is S<S<S<S>>>); //      4 >= 4
  Expect.isTrue(NFromInt(4) is! S<S<S<S<S>>>>); //  4 < 5

  Expect.isTrue(IsEven(NFromInt(0)));
  Expect.isFalse(IsEven(NFromInt(1)));
  Expect.isTrue(IsEven(NFromInt(2)));
  Expect.isFalse(IsEven(NFromInt(3)));
  Expect.isTrue(IsEven(NFromInt(4)));

  Expect.equals(0, IntFromN(NFromInt(0)));
  Expect.equals(1, IntFromN(NFromInt(1)));
  Expect.equals(2, IntFromN(NFromInt(2)));
  Expect.equals(50, IntFromN(NFromInt(50)));
}
