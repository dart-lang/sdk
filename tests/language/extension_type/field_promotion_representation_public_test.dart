// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the representation variable doesn't undergo field promotion if
// it's public.

// SharedOptions=--enable-experiment=inline-class

import '../static_type_helper.dart';

extension type E(Object Function() f) {
  testImplicitThisAccess() {
    if (f is int Function()) {
      f.expectStaticType<Exactly<Object Function()>>();
      f().expectStaticType<Exactly<Object>>();
    }
  }

  testExplicitThisAccess() {
    if (this.f is int Function()) {
      this.f.expectStaticType<Exactly<Object Function()>>();
      this.f().expectStaticType<Exactly<Object>>();
    }
  }
}

testGeneralPropertyAccess(E e) {
  if ((e).f is int Function()) {
    (e).f.expectStaticType<Exactly<Object Function()>>();
    (e).f().expectStaticType<Exactly<Object>>();
  }
}

testPrefixedIdentifierAccess(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test this form separately.
  if (e.f is int Function()) {
    e.f.expectStaticType<Exactly<Object Function()>>();
    e.f().expectStaticType<Exactly<Object>>();
  }
}

main() {
  int Function() f = () => 0;
  E(f).testImplicitThisAccess();
  E(f).testExplicitThisAccess();
  testGeneralPropertyAccess(E(f));
  testPrefixedIdentifierAccess(E(f));
}
