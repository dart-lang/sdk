// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class B<T> {
  B<T> operator +(B<T> other) => throw '';
}

class C<T> {
  B<F<T>> operator [](int i) => throw '';
  void operator []=(int i, B<F<T>> x) {}
}

class C2<T> {
  B<F<T>>? operator [](int i) => throw '';
  void operator []=(int i, B<F<T>>? x) {}
}

void test(C<num> c, C2<num> c2) {
  c[0] = new B<F<num>>();
  c2[0] = new B<F<num>>();
  c /*@checkReturn=B<(num) -> void>*/ [0] += new B<F<num>>();
  var x = c /*@checkReturn=B<(num) -> void>*/ [0] += new B<F<num>>();
  c2 /*@checkReturn=B<(num) -> void>?*/ [0] ??= new B<F<num>>();
  var y = c2 /*@checkReturn=B<(num) -> void>?*/ [0] ??= new B<F<num>>();
}

main() {}
