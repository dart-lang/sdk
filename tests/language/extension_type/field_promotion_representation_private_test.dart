// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the representation variable may undergo field promotion, assuming
// that it's private.

// SharedOptions=--enable-experiment=inline-class

import '../static_type_helper.dart';

extension type E(Object Function() _f) {
  testImplicitThisAccess() {
    if (_f is int Function()) {
      _f.expectStaticType<Exactly<int Function()>>();
      _f().expectStaticType<Exactly<int>>();
    }
  }

  testExplicitThisAccess() {
    if (this._f is int Function()) {
      this._f.expectStaticType<Exactly<int Function()>>();
      this._f().expectStaticType<Exactly<int>>();
    }
  }
}

testGeneralPropertyAccess(E e) {
  if ((e)._f is int Function()) {
    (e)._f.expectStaticType<Exactly<int Function()>>();
    (e)._f().expectStaticType<Exactly<int>>();
  }
}

testPrefixedIdentifierAccess(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test this form separately.
  if (e._f is int Function()) {
    e._f.expectStaticType<Exactly<int Function()>>();
    e._f().expectStaticType<Exactly<int>>();
  }
}

main() {
  int Function() f = () => 0;
  E(f).testImplicitThisAccess();
  E(f).testExplicitThisAccess();
  testGeneralPropertyAccess(E(f));
  testPrefixedIdentifierAccess(E(f));
}
