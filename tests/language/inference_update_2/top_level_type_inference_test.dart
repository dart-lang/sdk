// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion works during top level type inference.  In the
// CFE, top level types are inferred earlier than method bodies, so this
// verifies that the data structures necessary to support field promotion have
// been initialized in time.

// SharedOptions=--enable-experiment=inference-update-2

class C {
  final int? _promotable;
  final int? _notPromotable; // due to D._notPromotable

  C(int i)
      : _promotable = i,
        _notPromotable = i;

  static final staticPromotable =
      ((C c) => c._promotable != null ? c._promotable : 0)(new C(0));

  static final staticNotPromotable =
      ((C c) => c._notPromotable != null ? c._notPromotable : 0)(new C(0));

  final instancePromotable =
      ((C c) => c._promotable != null ? c._promotable : 0)(new C(0));

  final instanceNotPromotable =
      ((C c) => c._notPromotable != null ? c._notPromotable : 0)(new C(0));

  late final instancePromotableViaThis = _promotable != null ? _promotable : 0;

  late final instanceNotPromotableViaThis =
      _notPromotable != null ? _notPromotable : 0;
}

class D {
  int? _notPromotable;
}

final topLevelPromotable =
    ((C c) => c._promotable != null ? c._promotable : 0)(new C(0));

final topLevelNotPromotable =
    ((C c) => c._notPromotable != null ? c._notPromotable : 0)(new C(0));

void acceptsInt(int x) {}

void testTopLevelPromotable() {
  var x = topLevelPromotable;
  // `x` has type `int` so this is ok
  acceptsInt(x);
}

void testTopLevelNotPromotable() {
  var x = topLevelNotPromotable;
  // `x` has type `int?` so this is ok
  x = null;
}

void testStaticPromotable() {
  var x = C.staticPromotable;
  // `x` has type `int` so this is ok
  acceptsInt(x);
}

void testStaticNotPromotable() {
  var x = C.staticNotPromotable;
  // `x` has type `int?` so this is ok
  x = null;
}

void testInstancePromotable(C c) {
  var x = c.instancePromotable;
  // `x` has type `int` so this is ok
  acceptsInt(x);
}

void testInstanceNotPromotable(C c) {
  var x = c.instanceNotPromotable;
  // `x` has type `int?` so this is ok
  x = null;
}

void testInstancePromotableViaThis(C c) {
  var x = c.instancePromotableViaThis;
  // `x` has type `int` so this is ok
  acceptsInt(x);
}

void testInstanceNotPromotableViaThis(C c) {
  var x = c.instanceNotPromotableViaThis;
  // `x` has type `int?` so this is ok
  x = null;
}

main() {}
