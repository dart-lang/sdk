// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

library float64x2_typed_list_test;

import 'dart:typed_data';

void test(Float64x2List l) {
  var a = l[0];
  var b = l[1];
  l[0] = b;
  l[1] = a;
}

bool compare(a, b) {
  return (a.x == b.x) && (a.y == b.y);
}

main() {
  var l = new Float64x2List(2);
  var a = new Float64x2(1.0, 2.0);
  var b = new Float64x2(3.0, 4.0);
  l[0] = a;
  l[1] = b;
  for (var i = 0; i < 41; i++) {
    test(l);
  }
  if (!compare(l[0], b) || !compare(l[1], a)) {
    throw 123;
  }
}
