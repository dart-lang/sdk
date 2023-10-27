// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that flow analysis treats representation variables as independent of
// extension type objects. That is, if `e` is a promotable expression whose type
// is an extension type, and its representation variable is `_f`, null checks
// and `is` tests applied to `e` should not affect the type of `e._f`.
//
// SharedOptions=--enable-experiment=inline-class

import '../static_type_helper.dart';

extension type E(Object Function() _f) {
  testImplicitThisAccess() {
    if (this is int Function()) {
      _f.expectStaticType<Exactly<Object Function()>>();
      _f().expectStaticType<Exactly<Object>>();
    }
  }

  testExplicitThisAccess() {
    if (this._f is Object Function()) {
      this._f.expectStaticType<Exactly<Object Function()>>();
      this._f().expectStaticType<Exactly<Object>>();
    }
  }
}

testGeneralPropertyAccess(E e) {
  if (e is int Function()) {
    (e)._f.expectStaticType<Exactly<Object Function()>>();
    (e)._f().expectStaticType<Exactly<Object>>();
  }
}

testPrefixedIdentifierAccess(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test this form separately.
  if (e is int Function()) {
    e._f.expectStaticType<Exactly<Object Function()>>();
    e._f().expectStaticType<Exactly<Object>>();
  }
}

main() {
  int Function() f = () => 0;
  E(f).testImplicitThisAccess();
  E(f).testExplicitThisAccess();
  testGeneralPropertyAccess(E(f));
  testPrefixedIdentifierAccess(E(f));
}
