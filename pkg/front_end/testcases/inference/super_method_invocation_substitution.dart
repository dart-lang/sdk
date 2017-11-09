// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

T f<T>() => null;

class B<T> {
  List<T> g(Map<int, T> x) => null;
}

class C<U> extends B<Future<U>> {
  void h() {
    var /*@type=List<Future<C::U>>*/ x =
        super. /*@target=B::g*/ g(/*@typeArgs=Map<int, Future<C::U>>*/ f());
  }
}

main() {}
