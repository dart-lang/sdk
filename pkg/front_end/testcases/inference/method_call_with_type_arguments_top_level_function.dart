// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

D<T> f<T>() => throw '';

class D<T> {}

var g = f<int>();

test() {
  g;
}
