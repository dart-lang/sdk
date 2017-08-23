// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef F<T>(T x);

class C<T> {
  void f(T /*@checkFormal=semiSafe*/ x) {}
  void g1(T /*@checkFormal=semiSafe*/ x) {
    this.f(x);
  }

  void g2(T /*@checkFormal=semiSafe*/ x) {
    f(x);
  }

  void g3(C<T> /*@checkFormal=semiSafe*/ c, T /*@checkFormal=semiSafe*/ x) {
    c.f /*@checkCall=interface(semiTyped:0)*/ (x);
  }

  F<T> g4() => this.f;
}

class D extends C<int> {}

class E extends C<num> {
  void f(covariant int /*@checkFormal=unsafe*/ x) {}
}

test() {
  var x = new D().g4() as F<Object>;
  x /*@checkCall=interface(semiTyped:0)*/ ('hi');
  new E().g1(1.5);
}

main() {}
