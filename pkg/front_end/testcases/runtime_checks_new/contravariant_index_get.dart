// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef void F<T>(T x);

class C<T> {
  F<T> operator [](int i) => throw '';
}

F<num> test(C<num> c) {
  return c[0];
}

main() {}
