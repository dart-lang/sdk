// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T t);

abstract class A<T> {
  void f(T /*@covariance=genericInterface, genericImpl*/ x, int y);
}

class B<T> implements A<F<T>> {
  void f(F<T> /*@covariance=genericImpl*/ x, int y) {}
}

abstract class I<T> implements A<F<T>> {
  void f(F<T> /*@covariance=genericImpl*/ x, Object y);
}

class
/*@forwardingStub=abstract void f(covariance=(genericInterface, genericImpl) ((C::T) -> void) -> void x, covariance=() Object y)*/
    C<T> extends B<F<T>> implements I<F<T>> {}

void main() {}
