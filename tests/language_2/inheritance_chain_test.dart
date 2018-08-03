// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "inheritance_chain_lib.dart";

class A extends B {
  get id => "A";
  get length => 1;
}

class C extends D {
  get id => "C";
  get length => 3;
}

class X extends W {
  get id => "X";
  get length => -3;
}

class Z extends Y {
  get id => "Z";
  get length => -1;
}

main() {
  var instances = <dynamic>[
    new A(),
    new B(),
    new C(),
    new D(),
    new W(),
    new X(),
    new Y(),
    new Z(),
    [],
  ];

  var o = instances[0];
  Expect.equals("A", o.id);
  Expect.equals(1, o.length);
  Expect.isTrue(o is A);
  Expect.isTrue(o is B);
  Expect.isTrue(o is C);
  Expect.isTrue(o is D);
  Expect.isTrue(o is W);
  Expect.isTrue(o is X);
  Expect.isTrue(o is Y);
  Expect.isTrue(o is Z);
  o = instances[1];
  Expect.equals("B", o.id);
  Expect.equals(2, o.length);
  Expect.isTrue(o is B);
  Expect.isTrue(o is C);
  Expect.isTrue(o is D);
  Expect.isTrue(o is W);
  Expect.isTrue(o is X);
  Expect.isTrue(o is Y);
  Expect.isTrue(o is Z);
  o = instances[2];
  Expect.equals("C", o.id);
  Expect.equals(3, o.length);
  Expect.isTrue(o is C);
  Expect.isTrue(o is D);
  Expect.isTrue(o is W);
  Expect.isTrue(o is X);
  Expect.isTrue(o is Y);
  Expect.isTrue(o is Z);
  o = instances[3];
  Expect.equals("D", o.id);
  Expect.equals(4, o.length);
  Expect.isTrue(o is D);
  Expect.isTrue(o is W);
  Expect.isTrue(o is X);
  Expect.isTrue(o is Y);
  Expect.isTrue(o is Z);
  o = instances[4];
  Expect.equals("W", o.id);
  Expect.equals(-4, o.length);
  Expect.isTrue(o is W);
  o = instances[5];
  Expect.equals("X", o.id);
  Expect.equals(-3, o.length);
  Expect.isTrue(o is X);
  Expect.isTrue(o is W);
  o = instances[6];
  Expect.equals("Y", o.id);
  Expect.equals(-2, o.length);
  Expect.isTrue(o is Y);
  Expect.isTrue(o is X);
  Expect.isTrue(o is W);
  o = instances[7];
  Expect.equals("Z", o.id);
  Expect.equals(-1, o.length);
  Expect.isTrue(o is Z);
  Expect.isTrue(o is Y);
  Expect.isTrue(o is X);
  Expect.isTrue(o is W);
  o = instances[8];
  Expect.equals(0, o.length);
}
