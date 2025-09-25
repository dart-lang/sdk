// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

typedef Iterable<num> F(int x);
typedef List<int> G(double x);

T generic<T>(a(T _), b(T _)) => throw '';

test() {
  var v = generic((F f) => null, (G g) => null);
}
