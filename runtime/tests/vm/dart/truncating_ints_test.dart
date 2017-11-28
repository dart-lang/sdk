// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--limit-ints-to-64-bits --enable-inlining-annotations --optimization_counter_threshold=10 --no-use-osr --no-background-compilation

// Test for truncating (wrap-around) integer arithmetic in --limit-ints-to-64-bits mode.

import "package:expect/expect.dart";

const alwaysInline = "AlwaysInline";
const neverInline = "NeverInline";

@neverInline
add_smi(var a, var b) => a + b;

@neverInline
add_mint(var a, var b) => a + b;

@neverInline
add_mint_consts() => 0x5000000000000000 + 0x6000000000000000;

@neverInline
test_add(var v2, var v3, var v3fxx, var v5fxx, var v7fxx, var n60xx) {
  for (var i = 0; i < 20; i++) {
    Expect.equals(5, add_smi(v2, v3));
  }

  // Trigger deoptimization and re-compilation
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x4000000000000001, add_smi(v2, v3fxx));
  }

  for (var i = 0; i < 20; i++) {
    Expect.equals(-1, add_mint(v5fxx, n60xx));
  }

  // Wrap-around
  for (var i = 0; i < 20; i++) {
    Expect.equals(-0x2000000000000002, add_mint(v5fxx, v7fxx));
  }

  // Constant folding
  for (var i = 0; i < 20; i++) {
    Expect.equals(-0x5000000000000000, add_mint_consts());
  }
}

@neverInline
sub_smi(var a, var b) => a - b;

@neverInline
sub_mint(var a, var b) => a - b;

@neverInline
sub_mint_consts() => (-0x5000000000000000) - 0x6000000000000000;

@neverInline
test_sub(var v2, var v3, var v3fxx, var v5fxx, var v7fxx, var n60xx) {
  for (var i = 0; i < 20; i++) {
    Expect.equals(1, sub_smi(v3, v2));
  }

  // Trigger deoptimization and re-compilation
  for (var i = 0; i < 20; i++) {
    Expect.equals(-0x7ffffffffffffffe, sub_smi(-v3fxx, v3fxx));
  }

  for (var i = 0; i < 20; i++) {
    Expect.equals(0x2000000000000000, sub_mint(v7fxx, v5fxx));
  }

  // Wrap-around
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x4000000000000001, sub_mint(n60xx, v5fxx));
  }

  // Constant folding
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x5000000000000000, sub_mint_consts());
  }
}

@neverInline
mul_smi(var a, var b) => a * b;

@neverInline
mul_mint(var a, var b) => a * b;

@neverInline
mul_mint_consts() => 0x5000000000000001 * 0x6000000000000001;

@neverInline
test_mul(var v2, var v3, var v3fxx, var v5fxx, var v7fxx, var n60xx) {
  for (var i = 0; i < 20; i++) {
    Expect.equals(6, mul_smi(v2, v3));
  }

  // Trigger deoptimization and re-compilation
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x7ffffffffffffffe, mul_smi(v2, v3fxx));
  }

  // Wrap around
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x1ffffffffffffffd, mul_mint(v5fxx, 3));
  }

  // Constant folding
  for (var i = 0; i < 20; i++) {
    Expect.equals(-0x4fffffffffffffff, mul_mint_consts());
  }
}

@neverInline
shl_smi(var a, var b) => a << b;

@neverInline
shl_mint(var a, var b) => a << b;

@neverInline
shl_mint_by_const16(var a) => a << 16;

@neverInline
shl_smi_by_const96(var a) => a << 96;

@neverInline
shl_mint_by_const96(var a) => a << 96;

@neverInline
shl_mint_consts() => 0x77665544aabbccdd << 48;

@neverInline
test_shl(var v2, var v3, var v8, var v40) {
  for (var i = 0; i < 20; i++) {
    Expect.equals(16, shl_smi(v2, v3));
  }

  // Trigger deoptimization and re-compilation, wrap-around
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x5566770000000000, shl_smi(0x0011223344556677, v40));
  }

  // Wrap around
  for (var i = 0; i < 20; i++) {
    Expect.equals(-0x554433ffeeddcd00, shl_mint(0x7faabbcc00112233, v8));
  }

  // Shift mint by small constant
  for (var i = 0; i < 20; i++) {
    Expect.equals(0x5544332211aa0000, shl_mint_by_const16(0x77665544332211aa));
  }

  // Shift smi by large constant
  for (var i = 0; i < 20; i++) {
    Expect.equals(0, shl_smi_by_const96(0x77665544332211));
  }

  // Shift mint by large constant
  for (var i = 0; i < 20; i++) {
    Expect.equals(0, shl_mint_by_const96(0x77665544332211aa));
  }

  // Constant folding
  for (var i = 0; i < 20; i++) {
    Expect.equals(-0x3323000000000000, shl_mint_consts());
  }
}

test_literals() {
  Expect.equals(0x7fffffffffffffff, 9223372036854775807);
  Expect.equals(0x8000000000000000, -9223372036854775808);
  Expect.equals(0x8000000000000000, -0x8000000000000000);
  Expect.equals(0x8000000000000001, -0x7fffffffffffffff);
  Expect.equals(0xabcdef0123456789, -0x543210FEDCBA9877);
  Expect.equals(0xffffffffffffffff, -1);
  Expect.equals(-9223372036854775808, -0x8000000000000000);
  Expect.equals(9223372036854775807 + 1, -9223372036854775808);
}

main() {
  var v2 = 2; // smi
  var v3 = 3; // smi
  var v8 = 8; // smi
  var v40 = 40; // smi
  var v3fxx = 0x3fffffffffffffff; // max smi
  var v5fxx = 0x5fffffffffffffff; // mint
  var v7fxx = 0x7fffffffffffffff; // max mint
  var n60xx = -0x6000000000000000; // negative mint

  test_add(v2, v3, v3fxx, v5fxx, v7fxx, n60xx);
  test_sub(v2, v3, v3fxx, v5fxx, v7fxx, n60xx);
  test_mul(v2, v3, v3fxx, v5fxx, v7fxx, n60xx);
  test_shl(v2, v3, v8, v40);
  test_literals();
}
