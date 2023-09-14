// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests interactions between field promotion logic and object patterns.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C {
  final int? _field;
  int? _nonPromotable;
  C(this._field) : _nonPromotable = _field;
}

class D {
  final C _c;
  C _unstableC;
  D(this._c) : _unstableC = _c;
}

void promoteViaObjectPattern(C c) {
  if (c case C(_field: _?)) {
    c._field.expectStaticType<Exactly<int>>();
  }
  if (c case C(_nonPromotable: _?)) {
    c._nonPromotable.expectStaticType<Exactly<int?>>();
  }
}

void promoteViaObjectPattern_nested(D d) {
  if (d case D(_c: C(_field: _?))) {
    d._c._field.expectStaticType<Exactly<int>>();
  }
  if (d case D(_c: C(_nonPromotable: _?))) {
    d._c._nonPromotable.expectStaticType<Exactly<int?>>();
  }
  if (d case D(_unstableC: C(_field: _?))) {
    d._unstableC._field.expectStaticType<Exactly<int?>>();
  }
}

void matchedValueTypeBasedOnPreviousPromotion(C c) {
  if (c._field != null) {
    if (c case C(_field: var i)) {
      i.expectStaticType<Exactly<int>>();
    }
  }
  if (c._nonPromotable != null) {
    if (c case C(_nonPromotable: var i)) {
      i.expectStaticType<Exactly<int?>>();
    }
  }
}

void matchedValueTypeBasedOnPreviousPromotion_nested(D d) {
  if (d._c._field != null) {
    if (d case D(_c: C(_field: var i))) {
      i.expectStaticType<Exactly<int>>();
    }
  }
  if (d._c._nonPromotable != null) {
    if (d case D(_c: C(_nonPromotable: var i))) {
      i.expectStaticType<Exactly<int?>>();
    }
  }
  if (d._unstableC._field != null) {
    if (d case D(_unstableC: C(_field: var i))) {
      i.expectStaticType<Exactly<int?>>();
    }
  }
}

main() {
  promoteViaObjectPattern(C(0));
  promoteViaObjectPattern_nested(D(C(0)));
  matchedValueTypeBasedOnPreviousPromotion(C(0));
  matchedValueTypeBasedOnPreviousPromotion_nested(D(C(0)));
}
