// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a mixin's `on` clause is properly accounted for when determining
// whether field promotion should be inhibited due to a `noSuchMethod`
// forwarder.

// SharedOptions=--enable-experiment=inference-update-2

import "../static_type_helper.dart";

mixin M on C {}

class C {
  final int? _f1;
  C(this._f1);
}

class D implements M {
  @override
  noSuchMethod(_) => 0;
}

class E extends C {
  final int? _f2;
  E(this._f2) : super(_f2);
}

testOnClauseAffectsInterface(E e) {
  // The presence of the clause `on C` in the declaration of `mixin M` means
  // that `M` contains a getter named `_f1` in its interface. Consequently,
  // class `D` will have a `noSuchMethod` forwarder for `_f1`, defeating
  // promotion for `E._f1`.
  if (e._f1 != null) {
    e._f1.expectStaticType<Exactly<int?>>;
  }
}

testBasicPromotion(E e) {
  // Since the above test checks that field promotion *fails*, if we've made a
  // mistake causing field promotion to be completely disabled in this file, the
  // test will continue to pass. So to verify that we haven't made such a
  // mistake, verify that field promotion works under ordinary circumstances.
  if (e._f2 != null) {
    e._f2.expectStaticType<Exactly<int>>;
  }
}

main() {
  for (var e in [E(null), E(0)]) {
    testOnClauseAffectsInterface(e);
    testBasicPromotion(e);
  }
}
