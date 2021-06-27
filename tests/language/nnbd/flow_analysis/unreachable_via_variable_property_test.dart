// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test verifies that `is` and `==` tests performed on a property get of a
/// variable do not lead to code being considered unreachable.  (In principle,
/// we could soundly mark some such code as unreachable, but we have decided not
/// to do so at this time).
///
/// Exception: when the static type of the property access is guaranteed to be
/// Null, and we are performing an `== null` test, then we do mark the non-null
/// branch as unreachable.

import '../../static_type_helper.dart';

class C {
  Null get nullProperty => null;
  Object? get objectQProperty => null;
}

void equalitySimple(int? x, int? y, C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c.nullProperty == null) {
    x = null;
  } else {
    y = null;
  }
  // Since the assignment to x was reachable, it should have static type
  // `int?` now.  But y should still have static type `int`.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int>>();
}

void equalityWithBogusPromotion(int? x, int? y, C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c.objectQProperty is Null) {
    if (c.objectQProperty == null) {
      x = null;
    } else {
      y = null;
    }
  }
  // Since the assignments to x and y were both reachable, they should have
  // static type `int?` now.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int?>>();
}

void isSimple(int? x, int? y, C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c.nullProperty is Never) {
    x = null;
  } else {
    y = null;
  }
  // Since the assignments to x and y were both reachable, they should have
  // static type `int?` now.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int?>>();
}

void isWithBogusPromotion(int? x, int? y, C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c.objectQProperty is Null) {
    if (c.objectQProperty is Never) {
      x = null;
    } else {
      y = null;
    }
  }
  // Since the assignments to x and y were both reachable, they should have
  // static type `int?` now.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int?>>();
}

class _C {
  final Null _nullField = null;
  final Object? _objectQField = null;
}

void equalitySimplePrivate(int? x, int? y, _C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._nullField == null) {
    x = null;
  } else {
    y = null;
  }
  // Since the assignment to x was reachable, it should have static type
  // `int?` now.  But y should still have static type `int`.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int>>();
}

void equalityWithBogusPromotionPrivate(int? x, int? y, _C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._objectQField is Null) {
    if (c._objectQField == null) {
      x = null;
    } else {
      y = null;
    }
  }
  // Since the assignments to x and y were both reachable, they should have
  // static type `int?` now.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int?>>();
}

void isSimplePrivate(int? x, int? y, _C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._nullField is Never) {
    x = null;
  } else {
    y = null;
  }
  // Since the assignments to x and y were both reachable, they should have
  // static type `int?` now.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int?>>();
}

void isWithBogusPromotionPrivate(int? x, int? y, _C c) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (c._objectQField is Null) {
    if (c._objectQField is Never) {
      x = null;
    } else {
      y = null;
    }
  }
  // Since the assignments to x and y were both reachable, they should have
  // static type `int?` now.
  x.expectStaticType<Exactly<int?>>();
  y.expectStaticType<Exactly<int?>>();
}

main() {
  equalitySimple(1, 1, C());
  equalityWithBogusPromotion(1, 1, C());
  isSimple(1, 1, C());
  isWithBogusPromotion(1, 1, C());
  equalitySimplePrivate(1, 1, _C());
  equalityWithBogusPromotionPrivate(1, 1, _C());
  isSimplePrivate(1, 1, _C());
  isWithBogusPromotionPrivate(1, 1, _C());
}
