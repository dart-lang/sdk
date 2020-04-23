// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final x;
  final y;
  final z;
  final t;

  const A([this.z = 99, tt = 100])
      : y = 499,
        t = tt,
        x = 3;
  const A.n({this.z: 99, tt: 100})
      : y = 499,
        t = tt,
        x = 3;
  const A.named({z, this.t})
      : y = 400 + z,
        this.z = z,
        x = 3;
  const A.named2({t, z, y, x})
      : x = t,
        y = z,
        z = y,
        t = x;

  toString() => "A $x $y $z $t";
}

const a1 = const A(99, 100);
const a2 = const A.named(z: 99, t: 100);
const a3 = const A.named2(t: 1, z: 2, y: 3, x: 4);
const a4 = const A();
const a5 = const A(99, 100);
const a5n = const A.n(tt: 100, z: 99);
const a6 = const A(1, 2);
const a6n = const A.n(z: 1, tt: 2);
const a7 = const A.named(z: 7);
const a8 = const A.named2();
const a9 = const A.named2(x: 4, y: 3, z: 2, t: 1);
const a10 = const A.named2(x: 1, y: 2, z: 3, t: 4);

main() {
  Expect.equals(3, a1.x);
  Expect.equals(499, a1.y);
  Expect.equals(99, a1.z);
  Expect.equals(100, a1.t);
  Expect.equals("A 3 499 99 100", a1.toString());
  Expect.identical(a1, a2);
  Expect.identical(a1, a4);
  Expect.identical(a1, a5);

  Expect.equals(1, a3.x);
  Expect.equals(2, a3.y);
  Expect.equals(3, a3.z);
  Expect.equals(4, a3.t);
  Expect.equals("A 1 2 3 4", a3.toString());

  Expect.equals(3, a6.x);
  Expect.equals(499, a6.y);
  Expect.equals(1, a6.z);
  Expect.equals(2, a6.t);
  Expect.equals("A 3 499 1 2", a6.toString());

  Expect.equals(3, a7.x);
  Expect.equals(407, a7.y);
  Expect.equals(7, a7.z);
  Expect.equals(null, a7.t);
  Expect.equals("A 3 407 7 null", a7.toString());

  Expect.equals(null, a8.x);
  Expect.equals(null, a8.y);
  Expect.equals(null, a8.y);
  Expect.equals(null, a8.t);
  Expect.equals("A null null null null", a8.toString());

  Expect.identical(a3, a9);

  Expect.equals(4, a10.x);
  Expect.equals(3, a10.y);
  Expect.equals(2, a10.z);
  Expect.equals(1, a10.t);
  Expect.equals("A 4 3 2 1", a10.toString());
}
