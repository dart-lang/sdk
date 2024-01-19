// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that when an extension type declaration includes an "implements"
// clause, and an attempt is made to promote a property of the underlying
// representation type, the promotability is inherited from the underlying
// representation type member.

// SharedOptions=--enable-experiment=inline-class

import '../static_type_helper.dart';

class C {
  final int? _promotable = 0;
  int? _notPromotable = 0;
}

extension type E(C c) implements C {
  void viaImplicitThis() {
    if (_promotable != null) {
      _promotable.expectStaticType<Exactly<int>>();
    }
    if (_notPromotable != null) {
      _notPromotable.expectStaticType<Exactly<int?>>();
    }
  }

  void viaExplicitThis() {
    if (this._promotable != null) {
      this._promotable.expectStaticType<Exactly<int>>();
    }
    if (this._notPromotable != null) {
      this._notPromotable.expectStaticType<Exactly<int?>>();
    }
  }
}

void viaGeneralPropertyAccess(E e) {
  if ((e)._promotable != null) {
    (e)._promotable.expectStaticType<Exactly<int>>();
  }
  if ((e)._notPromotable != null) {
    (e)._notPromotable.expectStaticType<Exactly<int?>>();
  }
}

void viaPrefixedIdentifier(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test this form separately.
  if (e._promotable != null) {
    e._promotable.expectStaticType<Exactly<int>>();
  }
  if (e._notPromotable != null) {
    e._notPromotable.expectStaticType<Exactly<int?>>();
  }
}

main() {
  E(C()).viaImplicitThis();
  E(C()).viaExplicitThis();
  viaGeneralPropertyAccess(E(C()));
  viaPrefixedIdentifier(E(C()));
}
