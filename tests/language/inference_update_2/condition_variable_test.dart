// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion works when the promotion condition is stored in a
// local variable.

import '../static_type_helper.dart';

class C {
  final Object? _o;
  C(this._o);
}

void usingNullCheck_withoutInterveningPromotion(C c) {
  bool b = c._o != null;
  if (b) {
    c._o.expectStaticType<Exactly<Object>>();
  }
}

void usingIsTest_withoutInterveningPromotion(C c) {
  bool b = c._o is int;
  if (b) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

void usingNullCheck_withInterveningRelatedPromotion(C c) {
  bool b = c._o != null;
  if (c._o != null) {
    c._o.expectStaticType<Exactly<Object>>();
  }
  if (b) {
    c._o.expectStaticType<Exactly<Object>>();
  }
}

void usingIsTest_withInterveningRelatedPromotion(C c) {
  bool b = c._o is int;
  if (c._o is int) {
    c._o.expectStaticType<Exactly<int>>();
  }
  if (b) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

void usingNullCheck_withInterveningUnrelatedPromotion(C c, int? i) {
  bool b = c._o != null;
  i!;
  if (b) {
    c._o.expectStaticType<Exactly<Object>>();
  }
}

void usingIsTest_withInterveningUnrelatedPromotion(C c, int? i) {
  bool b = c._o is int;
  i!;
  if (b) {
    c._o.expectStaticType<Exactly<int>>();
  }
}

void usingNullCheck_disabledByAssignment(C c, C c2) {
  bool b = c._o != null;
  if (c._o != null) {
    c._o.expectStaticType<Exactly<Object>>();
  }
  c = c2;
  if (b) {
    c._o.expectStaticType<Exactly<Object?>>();
  }
}

void usingIsTest_disabledByAssignment(C c, C c2) {
  bool b = c._o is int;
  if (c._o is int) {
    c._o.expectStaticType<Exactly<int>>();
  }
  c = c2;
  if (b) {
    c._o.expectStaticType<Exactly<Object?>>();
  }
}

main() {
  usingNullCheck_withoutInterveningPromotion(C(0));
  usingIsTest_withoutInterveningPromotion(C(0));
  usingNullCheck_withInterveningRelatedPromotion(C(0));
  usingIsTest_withInterveningRelatedPromotion(C(0));
  usingNullCheck_withInterveningUnrelatedPromotion(C(0), 1);
  usingIsTest_withInterveningUnrelatedPromotion(C(0), 1);
  usingNullCheck_disabledByAssignment(C(0), C(1));
  usingIsTest_disabledByAssignment(C(0), C(1));
}
