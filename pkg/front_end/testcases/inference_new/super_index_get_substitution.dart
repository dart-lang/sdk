// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

T f<T>() => throw '';

class D<T> {}

class E<T> extends D<T> {}

class B<T> {
  D<T> operator [](E<T> x) => throw '';
}

class C<U> extends B<Future<U>> {
  E<Future<U>> operator [](Object x) => throw '';
  void h() {
    var x = super[f()];
  }
}

main() {}
