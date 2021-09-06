// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  A.foo1(X x) {}
  A.foo2(X x, int y) {}
  A();
  factory A.bar1() => new A();
}

A<X> Function<X>(X) test1() => A.foo1; // Ok.
A<X> Function<X>(X) test2() => A.foo2; // Error.
A<X> Function<X>(X) test3() => A.new; // Error.
A<X> Function<X>(X) test4() => A<int>.new; // Error.
A<X> Function<X>(X) test5() => A<int, String>.new; // Error.
A<X> Function<X>(X) test6() => A<int>.foo1; // Error.
A<X> Function<X>(X) test7() => A<int, String>.foo1; // Error.
A<X> Function<X>(X) test8() => A<int>.foo2; // Error.
A<X> Function<X>(X) test9() => A<int, String>.foo2; // Error.
A<X> Function<X>() test10() => A.bar1; // Ok.
A<X> Function<X>(X) test11() => A.bar1; // Error.
A<int> Function() test12() => A<int>.bar1; // Ok.
A<int> Function() test13() => A.bar1; // Ok.

main() {}
