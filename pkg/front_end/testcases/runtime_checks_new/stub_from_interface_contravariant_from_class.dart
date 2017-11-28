// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

typedef void F<T>(T t);

class B<T> {
  T f(int x) {}
}

abstract class I<T> {
  T f(Object x);
}

class
/*@forwardingStub=abstract genericContravariant (C::T) -> void f(covariance=() Object x)*/
    C<T> extends B<F<T>> implements I<F<T>> {}

void main() {}
