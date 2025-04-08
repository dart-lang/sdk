// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "bigger_cyclic_helper_2.dart";
export "bigger_cyclic_helper_2.dart";

void get2(int i) {
  print("2: $i");
  if (i > 0) {
    get1(i - 1);
    get2(i - 1);
    get3(i - 1);
    get4(i - 1);
    get5(i - 1);
    get6(i - 1);
  }
}
