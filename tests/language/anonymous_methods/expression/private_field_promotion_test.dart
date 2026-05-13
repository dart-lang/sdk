// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=anonymous-methods

import '../../static_type_helper.dart';

class C {
  final Object? _x;

  C(this._x);

  void testParameterlessRebindsThis() {
    if (_x != null) {
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
      // Inside the anonymous method, `this` has a new binding, so `this._x` is
      // no longer promoted.
      C(0).=> _x.expectStaticType<Exactly<Object?>>;
      C(0).=> this._x.expectStaticType<Exactly<Object?>>;
      // After the anonymous method invocations, the outer `this` has been
      // restored, so `this._x` is promoted again.
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
    }
  }

  void testParameterfulDoesNotRebindThis() {
    if (_x != null) {
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
      // Inside the anonymous method, no new binding is created for `this`, so
      // `this._x` is still promoted.
      C(0).(p) => _x.expectStaticType<Exactly<Object>>;
      C(0).(p) => this._x.expectStaticType<Exactly<Object>>;
      // `p._x` is not promoted though.
      C(0).(p) => p._x.expectStaticType<Exactly<Object?>>;
      // Since `this` was not changed, `this._x` is still promoted.
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
    }
  }
}

void testParameterlessPromotionsCarriedInAndOut(C c) {
  if (c._x != null) {
    c._x.expectStaticType<Exactly<Object>>;
    // Inside the anonymous method, `this` refers to the same object as `c`, so
    // `this._x` is promoted.
    c.=> _x.expectStaticType<Exactly<Object>>;
    c.=> this._x.expectStaticType<Exactly<Object>>;
  }
  // The promotion is carried out again.
  c._x.expectStaticType<Exactly<Object?>>;
  if (c.=> _x is Object) {
    c._x.expectStaticType<Exactly<Object>>;
  }
  if (c.=> this._x is Object) {
    c._x.expectStaticType<Exactly<Object>>;
  }
}

void testParameterfulPromotionsNotCarriedIn(C c) {
  if (c._x != null) {
    c._x.expectStaticType<Exactly<Object>>;
    // Inside the anonymous method, `p` refers to the same object as `c`, but
    // `p._x` is not promoted because `p` is treated like a normal local
    // variable.
    c.(p) => p._x.expectStaticType<Exactly<Object?>>;
  }
}

main() {
  C(0).testParameterlessRebindsThis();
  C(0).testParameterfulDoesNotRebindThis();
  testParameterlessPromotionsCarriedInAndOut(C(0));
  testParameterfulPromotionsNotCarriedIn(C(0));
}
