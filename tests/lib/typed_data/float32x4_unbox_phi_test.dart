// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--max_deoptimization_counter_threshold=1000 --optimization-counter-threshold=10 --no-background-compilation

// Library tag to be able to run in html test framework.
library float32x4_unbox_regress_test;

import 'dart:typed_data';
import 'package:expect/expect.dart';

double testUnboxPhi(Float32x4List data) {
  var res = new Float32x4.zero();
  for (int i = 0; i < data.length; i++) {
    res += data[i];
  }
  return res.x + res.y + res.z + res.w;
}

main() {
  Float32x4List list = new Float32x4List(10);
  Float32List floatList = new Float32List.view(list.buffer);
  for (int i = 0; i < floatList.length; i++) {
    floatList[i] = i.toDouble();
  }
  for (int i = 0; i < 20; i++) {
    double r = testUnboxPhi(list);
    Expect.equals(780.0, r);
  }
}
