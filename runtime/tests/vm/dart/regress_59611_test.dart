// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Dart Project Fuzz Tester (1.101).
// Program generated as:
//   dart dartfuzz.dart --seed 1868073336 --no-fp --no-ffi --flat
// @dart=2.14

// VMOptions=--optimization_counter_threshold=1 --use-slow-path --deterministic

import "dart:typed_data";

Uint8ClampedList var9 = Uint8ClampedList(40);
bool var109 = true;
int var112 = 5;

main() {
  for (int loc0 = 0; loc0 < 41; loc0++) {
    var112 = var9[27] >>> (var109 ? 38 : 255);
  }
}
