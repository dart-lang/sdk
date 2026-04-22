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
      C(0).{
        // `this` has a new binding, so `this._x` is no longer promoted.
        _x.expectStaticType<Exactly<Object?>>;
        this._x.expectStaticType<Exactly<Object?>>;
      };
      // The outer `this` has been restored, so `this._x` is prmoted again.
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
    }
  }

  void testParameterfulDoesNotRebindThis() {
    if (_x != null) {
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
      C(0).(p) {
        // No new binding was created for `this`, so `this._x` is still
        // promoted.
        _x.expectStaticType<Exactly<Object>>;
        this._x.expectStaticType<Exactly<Object>>;
        // `p._x` is not promoted though.
        p._x.expectStaticType<Exactly<Object?>>;
      };
      // Since `this` was not changed, `this._x` is still promoted.
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
    }
  }
}

void testParameterlessPromotionsCarriedIn(C c) {
  if (c._x != null) {
    c._x.expectStaticType<Exactly<Object>>;
    c.{
      // `this` refers to the same object as `c`, so `this._x` is promoted.
      _x.expectStaticType<Exactly<Object>>;
      this._x.expectStaticType<Exactly<Object>>;
    };
  }
}

void testParameterfulPromotionsCarriedIn(C c) {
  if (c._x != null) {
    c._x.expectStaticType<Exactly<Object>>;
    c.(p) {
      // `p` refers to the same object as `c`, so `p._x` is promoted.
      p._x.expectStaticType<Exactly<Object>>;
    };
  }
}

main() {
  testParameterlessPromotionsCarriedIn(C(0));
  testParameterfulPromotionsCarriedIn(C(0));
  C(0).testParameterlessRebindsThis();
  C(0).testParameterfulDoesNotRebindThis();
}
