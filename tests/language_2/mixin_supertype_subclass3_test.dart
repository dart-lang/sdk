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

// In this test, M is declared as `class M = S_static with G;`.

class B {}

class C {}

class D {}

class E extends B with C implements D {}

class F extends E {}

class A
  = E with M; class M = B with G; class G //# 01: ok
  = E with M; class M = C with G; class G //# 02: static type warning
  = E with M; class M = D with G; class G //# 03: ok
  = E with M; class M = E with G; class G //# 04: ok
  = E with M; class M = F with G; class G //# 05: static type warning
{}

main() {
  new A();
}
