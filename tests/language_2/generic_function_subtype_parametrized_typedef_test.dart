// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the subtype relationship that includes parametrized typedefs and
// invariant occurrences of types.

typedef H<X> = void Function<Y extends X>();

class A {}

class B extends A {}

class C extends B {}

void foo(H<A> ha, H<B> hb, H<C> hc) {
  H<A> haa = ha; //# 01: ok
  H<A> hab = hb; //# 02: compile-time error
  H<A> hac = hc; //# 03: compile-time error

  H<B> hba = ha; //# 04: compile-time error
  H<B> hbb = hb; //# 05: ok
  H<B> hbc = hc; //# 06: compile-time error

  H<C> hca = ha; //# 07: compile-time error
  H<C> hcb = hb; //# 08: compile-time error
  H<C> hcc = hc; //# 09: ok
}

main() {}
