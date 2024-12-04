// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that in language versions prior to patterns support, `case
// null` is not treated specially by flow analysis.

// @dart=2.19

import 'package:expect/static_type_helper.dart';

// Checks that even if the type of the scrutinee is `Null`, and one of the cases
// matches `null`, the other `default` case is still considered reachable.
void test1(Null Function() f, int? i1, int? i2) {
  if (i1 != null && i2 != null) {
    i1.expectStaticType<Exactly<int>>();
    i2.expectStaticType<Exactly<int>>();
    switch (f()) {
      case null:
        i1 = null;
        break;
      default:
        i2 = null;
        break;
    }
    // Check that both switch cases were considered reachable by flow analysis.
    i1.expectStaticType<Exactly<int?>>();
    i2.expectStaticType<Exactly<int?>>();
  }
}

// Checks that if the type of the scrutinee is nullable, and one of the cases
// matches `null`, the scrutinee is not promoted in the other `default` case.
void test2(int? x) {
  switch (x) {
    case null:
      x.expectStaticType<Exactly<int?>>();
      break;
    default:
      x.expectStaticType<Exactly<int?>>();
      break;
  }
}

main() {
  test1(() => null, 1, 2);
  test2(null);
  test2(1);
}
