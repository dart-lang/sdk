// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test verifies that neither an `== null` nor an `is` test can promote the
// type of `this`.  (In principle, we could soundly do so, but we have decided
// not to do so at this time).

class C {
  void equality() {
    if (this == null) {
      this.expectStaticType<Exactly<C>>();
    } else {
      this.expectStaticType<Exactly<C>>();
    }
  }

  void isSameType() {
    if (this is C) {
      this.expectStaticType<Exactly<C>>();
    } else {
      this.expectStaticType<Exactly<C>>();
    }
  }

  void isSubtype() {
    if (this is D) {
      this.expectStaticType<Exactly<C>>();
    } else {
      this.expectStaticType<Exactly<C>>();
    }
  }
}

class D extends C {}

class E {}

class F extends E {}

extension on E {
  void equality() {
    if (this == null) {
      this.expectStaticType<Exactly<E>>();
    } else {
      this.expectStaticType<Exactly<E>>();
    }
  }

  void isSameType() {
    if (this is E) {
      this.expectStaticType<Exactly<E>>();
    } else {
      this.expectStaticType<Exactly<E>>();
    }
  }

  void isSubtype() {
    if (this is F) {
      this.expectStaticType<Exactly<E>>();
    } else {
      this.expectStaticType<Exactly<E>>();
    }
  }
}

class G {}

extension on G? {
  void equality() {
    if (this == null) {
      this.expectStaticType<Exactly<G?>>();
    } else {
      this.expectStaticType<Exactly<G?>>();
    }
  }

  void isSameType() {
    if (this is G?) {
      this.expectStaticType<Exactly<G?>>();
    } else {
      this.expectStaticType<Exactly<G?>>();
    }
  }

  void isSubtype() {
    if (this is G) {
      this.expectStaticType<Exactly<G?>>();
    } else {
      this.expectStaticType<Exactly<G?>>();
    }
  }
}

main() {
  C().equality();
  C().isSameType();
  C().isSubtype();
  E().equality();
  E().isSameType();
  E().isSubtype();
  G().equality();
  G().isSameType();
  G().isSubtype();
  (null as G?).equality();
  (null as G?).isSameType();
  (null as G?).isSubtype();
}
