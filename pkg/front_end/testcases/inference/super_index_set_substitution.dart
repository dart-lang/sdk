// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

T f<T>() => throw '';

class B<T> {
  void operator []=(Map<int, T> x, List<T> y) {}
}

class C<U> extends B<Future<U>> {
  void operator []=(Object x, Object y) {}
  void h() {
    super[f()] = f();
  }
}

main() {}
