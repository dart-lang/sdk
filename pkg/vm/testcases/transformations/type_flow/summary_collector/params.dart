// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

t1(a1, a2, a3) => a1.foo1() + a2.foo2() + a3.foo3();

t2(a3, a2, a1) => a1.foo1() + a2.foo2() + a3.foo3();

t3(a1, a2, a3, [a4, a5, a6]) =>
    a1.foo1() + a2.foo2() + a3.foo3() + a4.foo4() + a5.foo5() + a6.foo6();

t4(a1, a2, a3, [a6, a5, a4]) =>
    a1.foo1() + a2.foo2() + a3.foo3() + a4.foo4() + a5.foo5() + a6.foo6();

t5(a1, a2, a3, {a4, a5, a6}) =>
    a1.foo1() + a2.foo2() + a3.foo3() + a4.foo4() + a5.foo5() + a6.foo6();

t6(a1, a2, a3, {a6, a5, a4}) =>
    a1.foo1() + a2.foo2() + a3.foo3() + a4.foo4() + a5.foo5() + a6.foo6();

t7(a1, a2, a3, {a5, a4, a6}) =>
    a1.foo1() + a2.foo2() + a3.foo3() + a4.foo4() + a5.foo5() + a6.foo6();

calls(x1, x2, x3, x4, x5, x6, x7, x8, x9) {
  t1(x1, x2, x3);
  t2(x1, x2, x3);
  t3(x1, x2, x3);
  t3(x1, x2, x3, x4);
  t4(x1, x2, x3, x4, x5);
  t5(x1, x2, x3);
  t5(x1, x2, x3, a4: x4);
  t5(x1, x2, x3, a5: x4);
  t5(x1, x2, x3, a6: x4, a5: x5);
  t6(x1, x2, x3, a4: x4, a6: x5);
  t6(x1, x2, x3, a4: x4, a5: x5, a6: x6);
  t7(x1, x2, x3, a4: x4, a6: x5, a5: x6);
}

main() {}
