// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.12

import 'package:expect/static_type_helper.dart';

class C {
  void equality() {
    if (this == null) {
      // Comparison of non-nullable with null doesn't promote (remains C).
      this.expectStaticType<Exactly<C>>;
    } else {
      this.expectStaticType<Exactly<C>>;
    }
  }

  void isSameType() {
    if (this is C) {
      this.expectStaticType<Exactly<C>>;
    } else {
      // Trivially satisfied `is` test doesn't promote (remains C).
      this.expectStaticType<Exactly<C>>;
    }
  }

  void isSubtype() {
    if (this is D) {
      this.expectStaticType<Exactly<C>>;
    } else {
      this.expectStaticType<Exactly<C>>;
    }
  }
}

class D extends C {}

class E {}

class F extends E {}

extension on E {
  void equality() {
    if (this == null) {
      this.expectStaticType<Exactly<E>>;
    } else {
      this.expectStaticType<Exactly<E>>;
    }
  }

  void isSameType() {
    if (this is E) {
      this.expectStaticType<Exactly<E>>;
    } else {
      this.expectStaticType<Exactly<E>>;
    }
  }

  void isSubtype() {
    if (this is F) {
      this.expectStaticType<Exactly<E>>;
    } else {
      this.expectStaticType<Exactly<E>>;
    }
  }
}

class G {}

extension on G? {
  void equality() {
    if (this == null) {
      // Comparison of nullable with null doesn't promote on true branch (remains G?).
      this.expectStaticType<Exactly<G?>>;
    } else {
      this.expectStaticType<Exactly<G?>>;
    }
  }

  void isSameType() {
    if (this is G?) {
      this.expectStaticType<Exactly<G?>>;
    } else {
      this.expectStaticType<Exactly<G?>>;
    }
  }

  void isSubtype() {
    if (this is G) {
      this.expectStaticType<Exactly<G?>>;
    } else {
      // With promotion disabled, G? that is not G remains G?.
      this.expectStaticType<Exactly<G?>>;
    }
  }

  void nullAssertPatternAssignment() {
    (_!) = this;
    this.expectStaticType<Exactly<G?>>;
  }

  void nullAssertPatternVariableDeclaration() {
    var (_!) = this;
    this.expectStaticType<Exactly<G?>>;
  }

  void nullAssertPatternIfCase() {
    if (this case _!) {
      this.expectStaticType<Exactly<G?>>;
    }
  }

  void nullCheckPatternIfCase() {
    if (this case _?) {
      this.expectStaticType<Exactly<G?>>;
    } else {
      this.expectStaticType<Exactly<G?>>;
    }
  }

  void nullCheckPatternSwitch() {
    switch (this) {
      case _?:
        this.expectStaticType<Exactly<G?>>;
    }
  }

  void notEqualNullPatternIfCase() {
    if (this case != null) {
      this.expectStaticType<Exactly<G?>>;
    }
  }
}

extension type H(C r) {
  void equality() {
    if (this == null) {
      // Comparison of non-nullable with null doesn't promote (remains H).
      this.expectStaticType<Exactly<H>>;
    } else {
      this.expectStaticType<Exactly<H>>;
    }
  }

  void isSameType() {
    if (this is H) {
      this.expectStaticType<Exactly<H>>;
    } else {
      // Trivially satisfied `is` test doesn't promote (remains H).
      this.expectStaticType<Exactly<H>>;
    }
  }

  void isSubtype() {
    if (this is I) {
      this.expectStaticType<Exactly<H>>;
    } else {
      this.expectStaticType<Exactly<H>>;
    }
  }
}

extension type I(D r) implements H {}

main() {
  C().equality();
  C().isSameType();
  C().isSubtype();
  D().equality();
  D().isSameType();
  D().isSubtype();
  E().equality();
  E().isSameType();
  E().isSubtype();
  F().equality();
  F().isSameType();
  F().isSubtype();
  G().equality();
  G().isSameType();
  G().isSubtype();
  G().nullAssertPatternAssignment();
  G().nullAssertPatternVariableDeclaration();
  G().nullAssertPatternIfCase();
  G().nullCheckPatternIfCase();
  G().nullCheckPatternSwitch();
  G().notEqualNullPatternIfCase();
  (null as G?).equality();
  (null as G?).isSameType();
  (null as G?).isSubtype();
  (null as G?).nullCheckPatternIfCase();
  (null as G?).nullCheckPatternSwitch();
  (null as G?).notEqualNullPatternIfCase();
  H(C()).equality();
  H(C()).isSameType();
  H(C()).isSubtype();
  H(D()).equality();
  H(D()).isSameType();
  H(D()).isSubtype();
  I(D()).equality();
  I(D()).isSameType();
  I(D()).isSubtype();
}
