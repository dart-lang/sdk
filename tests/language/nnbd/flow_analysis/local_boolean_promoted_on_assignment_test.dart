// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that local variables can be used to perform type promotion
// even in the case where the assignment ot (or initialization of) the local
// variable promotes it.

test(int? x) {
  {
    bool? b = null; // Makes `bool` a type of interest for `b`
    b = x != null; // Promotes `b` to `bool`
    b.expectStaticType<Exactly<bool>>();
    if (b) {
      x.expectStaticType<Exactly<int>>();
    } else {
      x.expectStaticType<Exactly<int?>>();
    }
  }
  {
    Object b = Object();
    if (b is! bool) {
      // Makes `bool` a type of interest for `b`
      b = x != null; // Promotes `b` to `bool`
      b.expectStaticType<Exactly<bool>>();
      if (b) {
        x.expectStaticType<Exactly<int>>();
      } else {
        x.expectStaticType<Exactly<int?>>();
      }
    }
  }
  {
    bool? b = x != null; // Promotes `b` to `bool`
    b.expectStaticType<Exactly<bool>>();
    if (b) {
      x.expectStaticType<Exactly<int>>();
    } else {
      x.expectStaticType<Exactly<int?>>();
    }
  }
}

main() {
  test(null);
  test(0);
}
