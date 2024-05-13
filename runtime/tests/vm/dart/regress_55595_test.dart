// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/55595.

import 'dart:typed_data';

Uint8ClampedList var9 = Uint8ClampedList.fromList(<int>[4294967297]);
Uint8ClampedList? var10 = Uint8ClampedList.fromList([]);
int var61 = -76;

void foo1_Extension0() {
  int loc0 = 28;
  int loc2 = 0;
  do {
    var10 = var9.sublist(
        ((!((-87).isNegative) ? false : true) ? 0 : ~15) | var61--, 19);
  } while (++loc2 < 28);
}

main() {
  try {
    foo1_Extension0();
  } catch (e) {}
}
