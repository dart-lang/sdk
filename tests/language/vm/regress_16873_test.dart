// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--new_gen_semi_max_size=1 --no_inline_alloc

// Regression test for slow-path allocation in the allocation stub.

library map_test;

import 'dart:collection';

void testCollection(var collection, n) {
  for (int i = 0; i < n; i++) {
    if (i % 1000 == 0) print(i);
    collection.add(i);
  }
}

main() {
  const int N = 100000;
  testCollection(new LinkedHashSet(), N);
}
