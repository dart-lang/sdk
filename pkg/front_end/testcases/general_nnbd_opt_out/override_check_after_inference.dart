// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

class A {}

class B extends A {}

class C {
  void f(A x) {}
}

class D extends C {
  void f(x) {} // Inferred type: (A) -> void
}

class E extends D {
  void f(A x) {} // Ok
}

class F extends D {
  void f(B x) {}
}

main() {}
