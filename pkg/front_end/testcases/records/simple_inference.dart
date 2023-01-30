// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo1((int, String?) r) {
  var r2 = r;
}

foo2((int, String?) r, X Function<X>() f) {
  r = (0, f());
}

foo3() {
  (num, num) r = (3, 3.5)..$1.isEven;
}

foo4() {
  (num, num) r = (3 as dynamic, 3.5);
}

foo5((int, String?) r, (int, X) Function<X>() f) {
  r = f();
}

foo6((X, Y) Function<X, Y>(X x, Y y) f, int x, String y) {
  var r = f(x, y);
}

foo7((X, (Y, Z)) Function<X, Y, Z>(X x, Y y, Z z) f, int x, String y, bool? z) {
  var r = f(x, y, z);
}

class A8<X extends (X, Y), Y extends num> {}

foo8(A8 a) {}

class A9<X extends (Y, Z), Y extends num, Z extends String?> {}

foo9(A9 a) {}

class A10<X, Y> {}

A10<(T, T), T> foo10<T>() => throw 0;

bar10() {
  A10<Record, String> r = foo10();
}


main() {}
