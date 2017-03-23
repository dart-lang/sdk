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

class B {}

class C {}

class D {}

class E extends B with C implements D {}

class F extends E {}

class A extends E with M {}

class M
  extends B //# 01: ok
  extends C //# 02: static type warning
  extends D //# 03: ok
  extends E //# 04: ok
  extends F //# 05: static type warning
{}

main() {
  new A();
}
