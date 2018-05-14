// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef F<T>(T x);

class C<T> {
  void f(T /*@covariance=genericImpl*/ x) {}
  void g1(T /*@covariance=genericImpl*/ x) {
    this.f(x);
  }

  void g2(T /*@covariance=genericImpl*/ x) {
    f(x);
  }

  void g3(C<T> /*@covariance=genericImpl*/ c, T /*@covariance=genericImpl*/ x) {
    c.f(x);
  }

  F<T> g4() => this.f;
}

class D extends C<int> {}

class E extends C<num> {
  void f(covariant int /*@covariance=explicit*/ x) {}
}

test() {
  var x = new D().g4 /*@checkReturn=(int) -> dynamic*/ () as F<Object>;
  x('hi');
  new E().g1(1.5);
}

main() {}
