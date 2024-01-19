// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion of the representation variable works properly in
// cascade expressions.
//
// These tests specifically exercise extension types whose representation type
// is nullable, since those are handled differently by the front end than
// extension types whose representation type is non-nullable.

// SharedOptions=--enable-experiment=inline-class

import '../static_type_helper.dart';

extension type E(Object Function()? _f) {
  testExplicitThisAccess() {
    if (this._f != null) {
      this.._f.expectStaticType<Exactly<Object Function()>>();
      this.._f().expectStaticType<Exactly<Object>>();
    }
  }
}

testGeneralPropertyAccess(E e) {
  if (e._f != null) {
    e.._f.expectStaticType<Exactly<Object Function()>>();
    e.._f().expectStaticType<Exactly<Object>>();
  }
}

main() {
  int Function() f = () => 0;
  E(f).testExplicitThisAccess();
  testGeneralPropertyAccess(E(f));
}
