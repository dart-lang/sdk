// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that instantiate to bound could be run on partially defined
// type arguments supplied by type inference.

class A<T> {}

class B<T extends num, S extends List<T>> extends A<T> {
  B([T x]) {}
}

main() {
  B x; // No information is provided by type inference.
  var y = new B(3); // T is constrained by int <: T by the upwards context.
  A<int> z = new B(); // T is constrained by T <: int by the downwards context.
}
