// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/55663.

import 'dart:io';
import 'dart:typed_data';

Uint8ClampedList var10 = Uint8ClampedList.fromList(Int8List(15));
Map<bool, bool> var104 = <bool, bool>{false: false, true: true};

@pragma("vm:never-inline")
hide(x) => x;

@pragma("vm:never-inline")
foo3_Extension1(int par1) {
  for (int loc1 in Uint8List(27)) {
    switch (hide(0)) {
      case 621118835:
        var10 = Uint8ClampedList(30)
            .sublist((var104[true]! ? 14 : 42) | ~(ZLibOption.minLevel), -20);
        break;
    }
  }
}

main() {
  foo3_Extension1(0);
}
