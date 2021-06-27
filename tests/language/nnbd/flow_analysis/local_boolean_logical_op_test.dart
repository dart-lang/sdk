// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that local boolean variables can be used to perform type
// promotion even when combined using logical operators.  It also verifies that
// these type promotions are appropriately invalidated by reassignments.

testAnd(int? x, int? y, int? z, bool b) {
  {
    bool b1 = x is int;
    bool b2 = y is int;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    x = z;
    bool b2 = y is int;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    y = z;
    bool b2 = y is int;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    b1 = b;
    bool b2 = y is int;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    x = z;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    y = z;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    b1 = b;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    b2 = b;
    if (b1 && b2) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    x = z;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    y = z;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    b1 = b;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    x = z;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    y = z;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    b1 = b;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    b2 = b;
    bool b3 = b1 && b2;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    x = z;
    if (b3) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    y = z;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    b1 = b;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    b2 = b;
    if (b3) {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is int;
    bool b2 = y is int;
    bool b3 = b1 && b2;
    b3 = b;
    if (b3) {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
}

testOr(int? x, int? y, int? z, bool b) {
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    x = z;
    bool b2 = y is! int;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    y = z;
    bool b2 = y is! int;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    b1 = b;
    bool b2 = y is! int;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    x = z;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    y = z;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    b1 = b;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    b2 = b;
    if (b1 || b2) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    x = z;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    y = z;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    b1 = b;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    x = z;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    y = z;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    b1 = b;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    b2 = b;
    bool b3 = b1 || b2;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    x = z;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    y = z;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    b1 = b;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    b2 = b;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int>>();
      y.expectStaticType<Exactly<int>>();
    }
  }
  {
    bool b1 = x is! int;
    bool b2 = y is! int;
    bool b3 = b1 || b2;
    b3 = b;
    if (b3) {
    } else {
      x.expectStaticType<Exactly<int?>>();
      y.expectStaticType<Exactly<int?>>();
    }
  }
}

main() {
  testAnd(1, 2, 3, true);
  testAnd(1, 2, 3, false);
  testAnd(1, 2, null, true);
  testAnd(1, 2, null, false);
  testAnd(1, null, 3, true);
  testAnd(1, null, 3, false);
  testAnd(1, null, null, true);
  testAnd(1, null, null, false);
  testAnd(null, 2, 3, true);
  testAnd(null, 2, 3, false);
  testAnd(null, 2, null, true);
  testAnd(null, 2, null, false);
  testAnd(null, null, 3, true);
  testAnd(null, null, 3, false);
  testAnd(null, null, null, true);
  testAnd(null, null, null, false);
  testOr(1, 2, 3, true);
  testOr(1, 2, 3, false);
  testOr(1, 2, null, true);
  testOr(1, 2, null, false);
  testOr(1, null, 3, true);
  testOr(1, null, 3, false);
  testOr(1, null, null, true);
  testOr(1, null, null, false);
  testOr(null, 2, 3, true);
  testOr(null, 2, 3, false);
  testOr(null, 2, null, true);
  testOr(null, 2, null, false);
  testOr(null, null, 3, true);
  testOr(null, null, 3, false);
  testOr(null, null, null, true);
  testOr(null, null, null, false);
}
