// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../static_type_helper.dart';

// This test checks that local variables can be used to perform type promotion
// even in the case where the local variable is itself promoted.

test(int? x) {
  Object b = x != null;
  if (b is bool && b) {
    x.expectStaticType<Exactly<int>>();
  }
}

main() {
  test(null);
  test(0);
}
