// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that local functions capture `this` if their arguments refer to
// type parameters from the enclosing class.

import "package:expect/expect.dart";

typedef void B<T>(T v);

class MyFisk {}

class MyHest {}

class A<T> {
  var value;

  A(B<T> x) {
    // This function does not capture `this` explicitly, however it needs
    // to capture it in order to access T. Verify that we do it correctly.
    // If `this` is not captured then foo turns into (B<dynamic>) -> Null
    // which means that foo(x) would throw if T != dynamic.
    f(B<T> v) {}

    f(x);
  }

  foo<U>(B<T> x, B<U> y) {
    // This function does not capture `this` explicitly, verify that it still
    // can access `T`.
    f(B<T> v, B<U> y) {}

    f(x, y);
  }
}

void main() {
  new A<MyFisk>((MyFisk v) {});
  new A<MyFisk>((MyFisk v) {}).foo<MyHest>((MyFisk v) {}, (MyHest v) {});
}
