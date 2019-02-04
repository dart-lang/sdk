// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T t);

class B<T> {
  void f(F<T> x, int y) {}
}

abstract class I<T> {
  void f(F<T> x, Object y);
}

abstract class
/*@forwardingStub=void f(covariance=(genericImpl) ((C::T) -> void) -> void x, covariance=() Object y)*/
    C<T> extends B<F<T>> implements I<F<T>> {}

void main() {}
