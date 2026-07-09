// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_polymorphic_with_deopt

import "dart:typed_data";

Int64List var19 = Int64List(0);
int var61 = -9223372034707292161;
int? var62 = -34;
Map<int, String> var113 = <int, String>{39: 'kR\u{1f600}gSx', 5: ''};

foo0_2() {
  for (int loc1 in var19) {}
}

foo0_Extension0() {
  for (int loc0 = 0; loc0 < 35; loc0++) {
    int loc1 = 0;
    do {
      print(Int32x4List(42));
    } while (++loc1 < 15);
  }
}

foo1_Extension0() {
  for (int loc0 in Int16List(42)) {
    int loc1 = 0;
    do {
      var113.addAll(<int, String>{
        loc1: 'N3+&'.replaceRange(var61, var62, "X"),
      });
    } while (++loc1 < 4);
  }
}

main() {
  foo0_2();
  foo0_Extension0();
  try {
    foo1_Extension0();
  } catch (e) {
    print(e);
  }
}
