// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C<T> extends D<T> {
  f<U>(x) => throw '';
}

class D<T> {
  F<U> f<U>(U u) => throw '';
}

typedef V F<V>();

main() {}
