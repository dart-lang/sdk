// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final x;
  final y;
  final z;
  final t;

  const A(this.z, tt)
      : y = 499,
        t = tt,
        x = 3;
  const A.named(z, this.t)
      : y = 400 + z,
        this.z = z,
        x = 3;
  const A.named2(t, z, y, x)
      : x = t,
        y = z,
        z = y,
        t = x;

  toString() => "A $x $y $z $t";
}

const a1 = const A(99, 100);
const a2 = const A.named(99, 100);
const a3 = const A.named2(1, 2, 3, 4);

main() {
  Expect.equals(3, a1.x);
  Expect.equals(499, a1.y);
  Expect.equals(99, a1.z);
  Expect.equals(100, a1.t);
  Expect.equals("A 3 499 99 100", a1.toString());

  Expect.isTrue(identical(a1, a2));

  Expect.equals(1, a3.x);
  Expect.equals(2, a3.y);
  Expect.equals(3, a3.z);
  Expect.equals(4, a3.t);
  Expect.equals("A 1 2 3 4", a3.toString());
}
