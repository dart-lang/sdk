// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that all three steps of the instantiate-to-bound algorithm
// implementation, that is, substitution of variables in strongly connected
// components, substitution of dependencies in the acyclic remainder of the type
// variables graph, and using simply typed bounds, work together well on the
// same declaration.

class B<X, Y> {}

class C<X, Y> {}

class D<X extends B<X, Y>, Y extends C<X, Y>, Z extends X Function(Y),
    W extends num> {}

main() {
  D d;
}
