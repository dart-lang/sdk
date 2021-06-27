// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that a local variable whose value is `null` cannot be used
// in place of a literal `null` in flow analysis.

test(int? x) {
  if (x == null) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int>>();
  }
  int? y = null;
  if (x == y) {
    x.expectStaticType<Exactly<int?>>();
  } else {
    x.expectStaticType<Exactly<int?>>();
  }
}

main() {
  test(0);
  test(null);
}
