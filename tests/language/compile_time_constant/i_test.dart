// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final x;
  const A(this.x);
  const A.redirect(x) : this(x + 1);
  const A.optional([this.x = 5]);
}

class B extends A {
  const B(x, this.y) : super(x);
  const B.redirect(x, y) : this(x + 22, y + 22);
  const B.redirect2(x, y) : this.redirect3(x + 122, y + 122);
  const B.redirect3(x, y)
      : this.y = y,
        super.redirect(x);
  const B.optional(x, [this.y]) : super(x);
  const B.optional2([x, this.y]) : super(x);
  final y;
}

class C extends B {
  const C(x, y, this.z) : super(x, y);
  const C.redirect(x, y, z) : this(x + 33, y + 33, z + 33);
  const C.redirect2(x, y, z) : this.redirect3(x + 333, y + 333, z + 333);
  const C.redirect3(x, y, z)
      : this.z = z,
        super.redirect2(x, y);
  const C.optional(x, [y, this.z]) : super(x, y);
  const C.optional2([x, y, z])
      : this.z = z,
        super(x, y);
  const C.optional3([this.z]) : super.optional2();
  final z;
}

const a1 = const A(499);
const a2 = const A.redirect(10499);
const a3 = const A.optional();
const a1b = const A.redirect(498);
const a3b = const A(5);

const b1 = const B(99499, -99499);
const b2 = const B.redirect(1234, 5678);
const b3 = const B.redirect2(112233, 556677);
const b4 = const B.redirect3(332211, 776655);
const b5 = const B.optional(43526);
const b6 = const B.optional2(8642, 9753);
const b3b = const B(112233 + 122 + 1, 556677 + 122);
const b6b = const B(8642, 9753);

const c1 = const C(121, 232, 343);
const c2 = const C.redirect(12321, 23432, 34543);
const c3 = const C.redirect2(32123, 43234, 54345);
const c4 = const C.redirect3(313, 424, 535);
const c5 = const C.optional(191, 181, 171);
const c6 = const C.optional(-191);
const c7 = const C.optional2();
const c8 = const C.optional3(9911);
const c3b = const C(32123 + 333 + 122 + 1, 43234 + 333 + 122, 54345 + 333);

main() {
  Expect.equals(499, a1.x);
  Expect.equals(10500, a2.x);
  Expect.equals(5, a3.x);
  Expect.identical(a1, a1b);
  Expect.identical(a3, a3b);

  Expect.equals(99499, b1.x);
  Expect.equals(-99499, b1.y);
  Expect.equals(1256, b2.x);
  Expect.equals(5700, b2.y);
  Expect.equals(112233 + 122 + 1, b3.x);
  Expect.equals(556677 + 122, b3.y);
  Expect.equals(332211 + 1, b4.x);
  Expect.equals(776655, b4.y);
  Expect.equals(43526, b5.x);
  Expect.equals(null, b5.y);
  Expect.equals(8642, b6.x);
  Expect.equals(9753, b6.y);
  Expect.identical(b3, b3b);
  Expect.identical(b6, b6b);

  Expect.equals(121, c1.x);
  Expect.equals(232, c1.y);
  Expect.equals(343, c1.z);
  Expect.equals(12321 + 33, c2.x);
  Expect.equals(23432 + 33, c2.y);
  Expect.equals(34543 + 33, c2.z);
  Expect.equals(32123 + 333 + 122 + 1, c3.x);
  Expect.equals(43234 + 333 + 122, c3.y);
  Expect.equals(54345 + 333, c3.z);
  Expect.equals(313 + 122 + 1, c4.x);
  Expect.equals(424 + 122, c4.y);
  Expect.equals(535, c4.z);
  Expect.equals(191, c5.x);
  Expect.equals(181, c5.y);
  Expect.equals(171, c5.z);
  Expect.equals(-191, c6.x);
  Expect.equals(null, c6.y);
  Expect.equals(null, c6.z);
  Expect.equals(null, c7.x);
  Expect.equals(null, c7.y);
  Expect.equals(null, c7.z);
  Expect.equals(null, c8.x);
  Expect.equals(null, c8.y);
  Expect.equals(9911, c8.z);
  Expect.identical(c3, c3b);
}
