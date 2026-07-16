// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=this-promotion

// This test verifies that promoting an already-promoted `this` behaves
// correctly. That is, the decision of whether to promote should be based on
// whether the tested type is a subtype of the _previously promoted_ type, not
// whether it's a subtype of the original type of `this`.

import 'package:expect/static_type_helper.dart';

class C {
  void test() {
    if (this is D) {
      this.expectStaticType<Exactly<D>>;
      if (this is E) {
        // Cannot promote D to E, since E is not a subtype of D.
        this.expectStaticType<Exactly<D>>;
      }
      if (this is F) {
        // Can promote D to F, since F is a subtype of D.
        this.expectStaticType<Exactly<F>>;
      }
    }
  }
}

class D extends C {}

class E extends C {}

class F extends D {}

extension on C {
  void testExtension() {
    if (this is D) {
      this.expectStaticType<Exactly<D>>;
      if (this is E) {
        // Cannot promote D to E, since E is not a subtype of D.
        this.expectStaticType<Exactly<D>>;
      }
      if (this is F) {
        // Can promote D to F, since F is a subtype of D.
        this.expectStaticType<Exactly<F>>;
      }
    }
  }
}

extension type G(C r) {
  void test() {
    if (this is H) {
      this.expectStaticType<Exactly<H>>;
      if (this is I) {
        // Cannot promote H to I, since I is not a subtype of H.
        this.expectStaticType<Exactly<H>>;
      }
      if (this is J) {
        // Can promote H to J, since J is a subtype of H.
        this.expectStaticType<Exactly<J>>;
      }
    }
  }
}

extension type H(D r) implements G {}

extension type I(E r) implements G {}

extension type J(F r) implements H {}

main() {
  C().test();
  C().testExtension();
  D().test();
  D().testExtension();
  E().test();
  E().testExtension();
  F().test();
  F().testExtension();
  G(C()).test();
  G(D()).test();
  G(E()).test();
  G(F()).test();
  H(D()).test();
  H(F()).test();
  I(E()).test();
  J(F()).test();
}
