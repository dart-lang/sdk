// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program testing generic type allocations and generic type tests.
// Regression test for issue 8710.

class C1<T> {}

class C2<T> {}

class C3<T> extends C2<C1<T>> {}

class C4<T> extends C3<T> {
  f() => new C5<C1<T>>(new C1<T>());
}

class C5<T> {
  C5(T x);
} // Checked mode: x must be of type C1<String>.

main() {
  new C4<String>().f();
}
