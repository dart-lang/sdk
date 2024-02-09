// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the presence of a representation variable with a given name
// doesn't interfere with promotability of fields having the same name elsewhere
// in the library.

// SharedOptions=--enable-experiment=inline-class

import '../static_type_helper.dart';

extension type E(int? _field) {}

class C {
  final int? _field;
  C(this._field);
}

test(C c) {
  if (c._field != null) {
    c._field.expectStaticType<Exactly<int>>();
  }
}

main() {
  test(C(0));
}
