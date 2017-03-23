// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

// Validate the following test from section 12 ("Mixins") of the spec:
//
//     "Let M_A be a mixin derived from a class M with direct superclass
//     S_static.
//
//     Let A be an application of M_A.  It is a static warning if the
//     superclass of A is not a subtype of S_static."

// In this test, M is declared as `class M extends ... with G {}`, so
// `S_static` is the unnamed mixin application `... with G`.  Since this
// unnamed mixin application can't be derived from, all the cases should yield
// a warning.

class B {}

class C {}

class D {}

class E extends B with C implements D {}

class F extends E {}

class G {}

class A = E with M;

class M
  extends B with G //# 01: static type warning
  extends C with G //# 02: static type warning
  extends D with G //# 03: static type warning
  extends E with G //# 04: static type warning
  extends F with G //# 05: static type warning
{}

main() {
  new A();
}
