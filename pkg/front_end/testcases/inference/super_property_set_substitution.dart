// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

T f<T>() => null;

class B<T> {
  List<T> x;
}

class C<U> extends B<Future<U>> {
  void g() {
    super. /*@target=B::x*/ x = /*@typeArgs=List<Future<C::U>>*/ f();
  }
}

main() {}
