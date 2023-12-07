// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic allows promotion of abstract getters.
//
// See https://github.com/dart-lang/language/issues/3328 for the rationale for
// allowing this.

// SharedOptions=--enable-experiment=inference-update-2

abstract class C {
  int? get _f;
}

class D extends C {
  final int? _f;

  D(this._f);
}

void acceptsInt(int x) {}

void testBaseClass(C c) {
  if (c._f != null) {
    var x = c._f;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

void testDerivedClass(D d) {
  if (d._f != null) {
    var x = d._f;
    // `x` has type `int` so this is ok
    acceptsInt(x);
  }
}

main() {
  for (var f in [null, 0]) {
    testBaseClass(D(f));
    testDerivedClass(D(f));
  }
}
