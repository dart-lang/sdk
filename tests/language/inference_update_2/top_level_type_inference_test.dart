// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion works during top level type inference.  In the
// CFE, top level types are inferred earlier than method bodies, so this
// verifies that the data structures necessary to support field promotion have
// been initialized in time.

import 'package:expect/static_type_helper.dart';

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

void testTopLevelPromotable() {
  topLevelPromotable.expectStaticType<Exactly<int>>();
}

void testTopLevelNotPromotable() {
  topLevelNotPromotable.expectStaticType<Exactly<int?>>();
}

void testStaticPromotable() {
  C.staticPromotable.expectStaticType<Exactly<int>>();
}

void testStaticNotPromotable() {
  C.staticNotPromotable.expectStaticType<Exactly<int?>>();
}

void testInstancePromotable(C c) {
  c.instancePromotable.expectStaticType<Exactly<int>>();
}

void testInstanceNotPromotable(C c) {
  c.instanceNotPromotable.expectStaticType<Exactly<int?>>();
}

void testInstancePromotableViaThis(C c) {
  c.instancePromotableViaThis.expectStaticType<Exactly<int>>();
}

void testInstanceNotPromotableViaThis(C c) {
  c.instanceNotPromotableViaThis.expectStaticType<Exactly<int?>>();
}

main() {}
