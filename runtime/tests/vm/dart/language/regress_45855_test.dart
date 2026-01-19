// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--optimization-counter-threshold=100 --deterministic
//
// The Dart Project Fuzz Tester (1.89).
// Program generated as:
//   dart dartfuzz.dart --seed 928581289 --no-fp --ffi --no-flat
//
// Minimized.

@pragma('vm:never-inline')
void main2(bool? boolParam) {
  for (int i = 0; i < 200; i++) {
    final bool1 = boolParam ?? false;
    if (bool1) {
      () {
        // Force creating a new current context.
        i.toString();
      };
      // Force having multiple paths to the exit, popping the current context.
      break;
    }
  }
}

void main() {
  // Test OSR.
  main2(null);

  // Test non-OSR.
  main2(null);
}
