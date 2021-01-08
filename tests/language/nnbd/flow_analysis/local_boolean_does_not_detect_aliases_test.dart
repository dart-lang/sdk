// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that type promotion via local variables does not promote
// based on knowledge that two potentially promoted variables are "aliases" of
// each other (both are known to contain the same value).
//
// Note, however, that if one condition variable is assigned to another, the
// promotions *do* carry over; this is a side effect of "promote via local
// booleans" mechanism and doesn't rely on detecting aliasing.
//
// We test both the situation where the variables have the same value due to
// initialization as well as assignment.  We test both final and non-final
// variables.

promotedVar(int? x) {
  {
    int? y = x;
    bool b = x != null;
    if (b) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    final int? y = x;
    bool b = x != null;
    if (b) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    int? y;
    y = x;
    bool b = x != null;
    if (b) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    final int? y;
    y = x;
    bool b = x != null;
    if (b) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
}

conditionalVar(int? x) {
  {
    bool b1 = x != null;
    bool b2 = b1;
    if (b1) {
      x.expectStaticType<Exactly<int>>();
    }
    if (b2) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x != null;
    final bool b2 = b1;
    if (b1) {
      x.expectStaticType<Exactly<int>>();
    }
    if (b2) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x != null;
    bool b2;
    b2 = b1;
    if (b1) {
      x.expectStaticType<Exactly<int>>();
    }
    if (b2) {
      x.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x != null;
    final bool b2;
    b2 = b1;
    if (b1) {
      x.expectStaticType<Exactly<int>>();
    }
    if (b2) {
      x.expectStaticType<Exactly<int>>();
    }
  }
}

main() {
  promotedVar(0);
  promotedVar(null);
  conditionalVar(0);
  conditionalVar(null);
}
