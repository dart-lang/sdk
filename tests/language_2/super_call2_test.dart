// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regresion test for bug discovered in frog handling super calls: the test case
// mixes generics, super calls, and purposely doesn't allocate the base type.

class C<T> {
  foo(T a) {}
}

class D<T> extends C<T> {
  foo(T a) {
    super.foo(a); // used to be resolved incorrectly and generate this.foo(a).
  }
}

main() {
  var d = new D();
  d.foo(null);
}
