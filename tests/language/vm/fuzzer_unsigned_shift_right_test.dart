// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// VMOptions=--deterministic

// The Dart Project Fuzz Tester (1.93).
// Program generated as:
//   dart dartfuzz.dart --seed 316265767 --no-fp --no-ffi --flat

import 'dart:typed_data';

Int16List? foo0_0(int par4) {
  if (par4 >= 36) {
    return Int16List(40);
  }
  for (int loc0 = 0; loc0 < 31; loc0++) {
    for (int loc1 in ((Uint8ClampedList.fromList(Uint8List(26)))
        .sublist((11 >>> loc0), null))) {}
  }
  return foo0_0(par4 + 1);
}

main() {
  foo0_0(0);
}
