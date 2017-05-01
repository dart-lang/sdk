// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Check that optimizer correctly handles (x << y) & MASK_32 pattern on 32-bit
// platforms: given the pattern
//
//     v1 <- UnboxedIntConverter([tr] mint->uint32, v0)
//     v2 <- UnboxedIntConverter(uint32->mint, v1)
//
// optimizer must *not* replace v2 with v0 because the first conversion is
// truncating and is erasing the high part of the mint value.
//
// VMOptions=--optimization-counter-threshold=5 --no-background-compilation

import "package:expect/expect.dart";

const _MASK_32 = 0xffffffff;
int _rotl32(int val, int shift) {
  final mod_shift = shift & 31;
  return ((val << mod_shift) & _MASK_32) |
      ((val & _MASK_32) >> (32 - mod_shift));
}

rot8(v) => _rotl32(v, 8);

main() {
  // Note: value is selected in such a way that (value << 8) is not a smi - this
  // triggers emittion of BinaryMintOp instructions for shifts.
  const value = 0xF0F00000;
  const rotated = 0xF00000F0;
  Expect.equals(rotated, rot8(value));
  for (var i = 0; i < 10; i++) {
    Expect.equals(rotated, rot8(value));
  }
}
