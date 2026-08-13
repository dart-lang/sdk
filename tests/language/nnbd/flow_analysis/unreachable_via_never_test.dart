// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This test verifies that various constructs involving an expression of type
/// `Never` are properly treated by flow analysis as belonging to unreachable
/// code paths.

import 'package:expect/static_type_helper.dart';

void asExpression(int? x, int i) {
  if (x == null) {
    i as Never;
  }
  // Since no runtime object can have type `Never`, the code path after `i as
  // Never` should be unreachable.  Hence, `x` is promoted to static type `int`.
  x.expectStaticType<Exactly<int>>();
}

void ifNullExpression(int? x, Null Function() f) {
  if (x == null) {
    f() ?? (throw '');
  }
  // Since `f()` has static type `Null`, it must always evaluate to `null`,
  // hence the shortcut branch of `f() ?? throw ''` is unreachable.  This means
  // that the code path after the whole expression `f() ?? throw ''` should be
  // unreachable.  Hence, `x` is promoted to static type `int`.
  x.expectStaticType<Exactly<int>>();
}

void ifNullAssignment(int? x, Null n) {
  if (x == null) {
    n ??= throw '';
  }
  // Since `n` has static type `Null`, it must always be `null`, hence the
  // shortcut branch of `n ??= throw ''` is unreachable.  This means that the
  // code path after the whole expression `n ??= throw ''` should be
  // unreachable.  Hence, `x` is promoted to static type `int`.
  x.expectStaticType<Exactly<int>>();
}

void ifExpression(int? x, int? y, Object? Function() f) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  if (f() is Never) {
    x = null;
  } else {
    y = null;
  }
  // Since the assignment to y was reachable, it should have static type `int?`
  // now.  But x should still have static type `int`.
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int?>>();
}

void nonNullAssert(int? x, Null Function() f) {
  if (x == null) {
    f()!;
  }
  // Since `f()` has static type `Null`, it must always evaluate to `null`,
  // hence the non-null assertion always fails.  This means that the code path
  // after the whole expression `f()!` should be unreachable.  Hence, `x` is
  // promoted to static type `int`.
  x.expectStaticType<Exactly<int>>();
}

void nullAwareAccess(int? x, int? y, Null Function() f, Object? Function() g) {
  if (x == null || y == null) return;
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int>>();
  f()?.extensionMethod(x = null);
  g()?.extensionMethod(y = null);
  // Since `f()` has static type `Null`, it must always evaluate to `null`,
  // hence the assignment to x should be unreachable.
  // Since the assignment to y was reachable, it should have static type `int?`
  // now.  But x should still have static type `int`.
  x.expectStaticType<Exactly<int>>();
  y.expectStaticType<Exactly<int?>>();
}

extension on Object? {
  void extensionMethod(Object? o) {}
}

main() {
  asExpression(1, 1);
  ifNullExpression(1, () => null);
  ifNullAssignment(1, null);
  ifExpression(1, 1, () => 1);
  nonNullAssert(1, () => null);
  nullAwareAccess(1, 1, () => null, () => 1);
}
