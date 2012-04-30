// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing static final fields.

interface Spain {
  static final AG = "Antoni Gaudi";
  static final SD = "Salvador Dali";
}

interface Switzerland {
  static final AG = "Alberto Giacometti";
  static final LC = "Le Corbusier";
}

class A implements Switzerland {
  const A() : n = 5;
  final n;
  static final a = const A();
  static final b = 3 + 5;
  static final c = A.b + 7;
  static final d = const A();
  static final s1 = "hula";
  static final s2 = "hula";
  static final s3 = "hop";
  static final d1 = 1.1;
  static final d2 = 0.55 + 0.55;
  static final artist2 = Switzerland.AG;
  static final architect1 = Spain.AG;
  static final array1 = const <int>[1, 2];
  static final map1 = const {"Monday": 1, "Tuesday": 2, };
}

class StaticFinalFieldTest {
  static testMain() {
    Expect.equals(15, A.c);
    Expect.equals(8, A.b);
    Expect.equals(5, A.a.n);
    Expect.equals(true,  8 === A.b);
    Expect.equals(true,  A.a === A.d);
    Expect.equals(true,  A.s1 === A.s2);
    Expect.equals(false, A.s1 === A.s3);
    Expect.equals(false, A.s1 === A.b);
    Expect.equals(true,  A.d1 === A.d2);
    Expect.equals(true, Spain.SD == "Salvador Dali");
    Expect.equals(true, A.artist2 == "Alberto Giacometti");
    Expect.equals(true, A.architect1 == "Antoni Gaudi");
    Expect.equals(2, A.map1["Tuesday"]);
  }
}

main() {
  StaticFinalFieldTest.testMain();
}
