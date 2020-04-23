// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing static const fields.

import "package:expect/expect.dart";

abstract class Spain {
  static const AG = "Antoni Gaudi";
  static const SD = "Salvador Dali";
}

abstract class Switzerland {
  static const AG = "Alberto Giacometti";
  static const LC = "Le Corbusier";
}

class A implements Switzerland {
  const A() : n = 5;
  final n;
  static const a = const A();
  static const b = 3 + 5;
  static const c = A.b + 7;
  static const d = const A();
  static const s1 = "hula";
  static const s2 = "hula";
  static const s3 = "hop";
  static const d1 = 1.1;
  static const d2 = 0.55 + 0.55;
  static const artist2 = Switzerland.AG;
  static const architect1 = Spain.AG;
  static const array1 = const <int>[1, 2];
  static const map1 = const {
    "Monday": 1,
    "Tuesday": 2,
  };
}

class StaticFinalFieldTest {
  static testMain() {
    Expect.equals(15, A.c);
    Expect.equals(8, A.b);
    Expect.equals(5, A.a.n);
    Expect.equals(true, identical(8, A.b));
    Expect.equals(true, identical(A.a, A.d));
    Expect.equals(true, identical(A.s1, A.s2));
    Expect.equals(false, identical(A.s1, A.s3));
    Expect.equals(false, identical(A.s1, A.b));
    Expect.equals(true, identical(A.d1, A.d2));
    Expect.equals(true, Spain.SD == "Salvador Dali");
    Expect.equals(true, A.artist2 == "Alberto Giacometti");
    Expect.equals(true, A.architect1 == "Antoni Gaudi");
    Expect.equals(2, A.map1["Tuesday"]);
  }
}

main() {
  StaticFinalFieldTest.testMain();
}
