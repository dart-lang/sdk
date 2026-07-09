// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  void set x(A value) {}
  B get y => throw '';
}

class D extends C {
  void set x(value) {} // Inferred type: A
  get y => throw ''; // Inferred type: B
}

class E extends D {
  void set x(A value) {} // Ok
  B get y => throw ''; // Ok
}

class F extends D {
  void set x(B value) {}
  A get y => throw '';
}

main() {}
