// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for dart2js where the reference to [:this:] in a
// constructor was not propagated to the super initializers.

class A<T> {
  var map;
  // Usage of type variables in the initializer makes the SSA builder
  // want to access [:this:]. And because the initializers of A are
  // inlined in the constructor of B, we have to make sure the
  // [:this:] in the A constructor has a corresponding
  // SSA instruction.
  A() : map = new Map<T, T>();
}

class B<T> extends A<T> {}

main() {
  Expect.isTrue(new B<int>().map is Map<int, int>);
}
