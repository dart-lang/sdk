// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test location summary for Uint32 multiplication.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

const MASK = 0xFFFFFFFF;

uint32Mul(x, y) => (x * y) & MASK;

main() {
  for (var i = 0; i < 20; i++) uint32Mul((1 << 63) - 1, 1);
}
