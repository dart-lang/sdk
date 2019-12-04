// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

class B {}

class C {
  B call(B b) => b;
}

typedef B BToB(B x);

class D {
  BToB f() => null;
  void g(C x) {}
}

class E extends D {
  // This override is illegal because C is not a subtype of BToB.


  // This override is illegal because BToB is not a supertype of C.

}

main() {
  new E();
}
