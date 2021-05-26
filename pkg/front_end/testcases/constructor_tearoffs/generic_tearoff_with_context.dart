// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  A.foo1(X x) {}
  A.foo2(X x, int y) {}
}

A<X> Function<X>(X) bar1() => A.foo1; // Ok.
A<X> Function<X>(X) bar2() => A.foo2; // Error.

main() {}
