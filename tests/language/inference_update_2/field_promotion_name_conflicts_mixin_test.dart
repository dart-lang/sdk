// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests promotability for final private fields declared in mixins.
//
// A private final field declared in a mixin is promotable unless:
//
// - There is a non-final field with the same name declared elsewhere in the
//   library.
//
// - There is a concrete getter with the same name declared elsewhere in the
//   library.
//
// - There is a concrete class elsewhere in the library that implicitly contains
//   a noSuchMethod-forwarding getter with the same name.
//
// This test exercises both ordinary final fields and late final fields.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

// Main test mixin.
mixin class M {
  // Promotable, no conflicting declarations.
  final int? _nonLate1 = 0;
  late final int? _late1 = 0;
  // Not promotable due to same-named non-final field.
  final int? _nonLate2 = 0;
  late final int? _late2 = 0;
  // Not promotable due to same-named getter declaration.
  final int? _nonLate3 = 0;
  late final int? _late3 = 0;
  // Not promotable due to same-named nSM-forwarder.
  final int? _nonLate4 = 0;
  late final int? _late4 = 0;
}

// Classes mixing in the main test mixin.
class C1 extends Object with M {}

class C2 = Object with M;

// Interfering declarations.
class C3 implements C4 {
  // Any non-final field inhibits promotion, since it's not stable.
  int? _nonLate2;
  int? _late2;
  // Any concrete getter inhibits promotion, since it's assumed to not be
  // stable.
  int? get _nonLate3 => 0;
  int? get _late3 => 0;
  // Any noSuchMethod-forwarding getter inhibits promotion, since the
  // implementation of noSuchMethod is assumeb to not be stable. (Requires that
  // the class be concrete and fail to implement a part of its interface; such a
  // class is only allowed if it contains or inherits a noSuchMethod
  // declaration).
  noSuchMethod(Invocation invocation) => 0;
}

class C4 {
  final int? _nonLate4 = 0;
  final int? _late4 = 0;
}

void testPromotionOK(M m, C1 c1, C2 c2) {
  if (m._nonLate1 != null) {
    m._nonLate1.expectStaticType<Exactly<int>>();
  }
  if (m._late1 != null) {
    m._late1.expectStaticType<Exactly<int>>();
  }
  if (c1._nonLate1 != null) {
    c1._nonLate1.expectStaticType<Exactly<int>>();
  }
  if (c1._late1 != null) {
    c1._late1.expectStaticType<Exactly<int>>();
  }
  if (c2._nonLate1 != null) {
    c2._nonLate1.expectStaticType<Exactly<int>>();
  }
  if (c2._late1 != null) {
    c2._late1.expectStaticType<Exactly<int>>();
  }
}

void testConflictingNonFinalField(M m, C1 c1, C2 c2) {
  if (m._nonLate2 != null) {
    m._nonLate2.expectStaticType<Exactly<int?>>();
  }
  if (m._late2 != null) {
    m._late2.expectStaticType<Exactly<int?>>();
  }
  if (c1._nonLate2 != null) {
    c1._nonLate2.expectStaticType<Exactly<int?>>();
  }
  if (c1._late2 != null) {
    c1._late2.expectStaticType<Exactly<int?>>();
  }
  if (c2._nonLate2 != null) {
    c2._nonLate2.expectStaticType<Exactly<int?>>();
  }
  if (c2._late2 != null) {
    c2._late2.expectStaticType<Exactly<int?>>();
  }
}

void testConflictingGetter(M m, C1 c1, C2 c2) {
  if (m._nonLate3 != null) {
    m._nonLate3.expectStaticType<Exactly<int?>>();
  }
  if (m._late3 != null) {
    m._late3.expectStaticType<Exactly<int?>>();
  }
  if (c1._nonLate3 != null) {
    c1._nonLate3.expectStaticType<Exactly<int?>>();
  }
  if (c1._late3 != null) {
    c1._late3.expectStaticType<Exactly<int?>>();
  }
  if (c2._nonLate3 != null) {
    c2._nonLate3.expectStaticType<Exactly<int?>>();
  }
  if (c2._late3 != null) {
    c2._late3.expectStaticType<Exactly<int?>>();
  }
}

void testConflictingNSMForwardingGetter(M m, C1 c1, C2 c2) {
  if (m._nonLate4 != null) {
    m._nonLate4.expectStaticType<Exactly<int?>>();
  }
  if (m._late4 != null) {
    m._late4.expectStaticType<Exactly<int?>>();
  }
  if (c1._nonLate4 != null) {
    c1._nonLate4.expectStaticType<Exactly<int?>>();
  }
  if (c1._late4 != null) {
    c1._late4.expectStaticType<Exactly<int?>>();
  }
  if (c2._nonLate4 != null) {
    c2._nonLate4.expectStaticType<Exactly<int?>>();
  }
  if (c2._late4 != null) {
    c2._late4.expectStaticType<Exactly<int?>>();
  }
}

main() {
  testPromotionOK(M(), C1(), C2());
  testConflictingNonFinalField(M(), C1(), C2());
  testConflictingGetter(M(), C1(), C2());
  testConflictingNSMForwardingGetter(M(), C1(), C2());
}
