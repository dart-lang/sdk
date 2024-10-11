// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic allows promotion of abstract getters.
//
// See https://github.com/dart-lang/language/issues/3328 for the rationale for
// allowing this.

import 'package:expect/static_type_helper.dart';

abstract class C {
  int? get _f;
}

class D extends C {
  final int? _f;

  D(this._f);
}

void testBaseClass(C c) {
  if (c._f != null) {
    c._f.expectStaticType<Exactly<int>>();
  }
}

void testDerivedClass(D d) {
  if (d._f != null) {
    d._f.expectStaticType<Exactly<int>>();
  }
}

main() {
  for (var f in [null, 0]) {
    testBaseClass(D(f));
    testDerivedClass(D(f));
  }
}
