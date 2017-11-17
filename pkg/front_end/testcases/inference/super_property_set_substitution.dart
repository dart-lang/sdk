// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

T f<T>() => null;

class D<T> {}

class E<T> extends D<T> {}

class B<T> {
  D<T> x;
}

class C<U> extends B<Future<U>> {
  E<Future<U>> get x => null;
  void set x(Object x) {}
  void g() {
    super. /*@target=B::x*/ x = /*@typeArgs=D<Future<C::U>>*/ f();
  }
}

main() {}
