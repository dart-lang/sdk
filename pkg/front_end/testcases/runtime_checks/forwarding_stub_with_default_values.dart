// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B {
  Object _x;
  void f([num x = 10]) {
    _x = x;
  }

  void g({num x = 20}) {
    _x = x;
  }

  void check(Object expectedValue) {
    if (_x != expectedValue) {
      throw 'Expected _x == $expectedValue; got ${_x}';
    }
  }
}

abstract class I<T> {
  void f([T /*@covariance=genericImpl*/ x]);
  void g({T /*@covariance=genericImpl*/ x});
}

class
/*@forwardingStub=void f([covariance=(genericImpl) num x])*/
/*@forwardingStub=void g({covariance=(genericImpl) num x})*/
    C extends B implements I<num> {}

main() {
  C c = new C();
  c.f();
  c.check(10);
  c.g();
  c.check(20);
}
