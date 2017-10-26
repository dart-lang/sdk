// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T x);

class B<T> {
  B<T> operator +(B<T> /*@covariance=genericInterface, genericImpl*/ other) =>
      null;
}

class C<T> {
  B<F<T>> operator /*@genericContravariant=true*/ [](int i) => null;
  void operator []=(int i, B<F<T>> x) {}
}

void test(C<num> c) {
  c[0] = new B<F<num>>();
  c /*@checkReturn=B<(num) -> void>*/ [0] += new B<F<num>>();
  var x = c /*@checkReturn=B<(num) -> void>*/ [0] += new B<F<num>>();
  c /*@checkReturn=B<(num) -> void>*/ [0] ??= new B<F<num>>();
  var y = c /*@checkReturn=B<(num) -> void>*/ [0] ??= new B<F<num>>();
}

main() {}
