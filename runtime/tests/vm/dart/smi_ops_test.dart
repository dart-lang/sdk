// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=50 --no-background-compilation

import "package:expect/expect.dart";

@pragma("vm:never-inline")
dynamic smi_add(dynamic x, dynamic y) => x + y;

@pragma("vm:never-inline")
dynamic smi_sub(dynamic x, dynamic y) => x - y;

@pragma("vm:never-inline")
dynamic smi_mul(dynamic x, dynamic y) => x * y;

@pragma("vm:never-inline")
dynamic smi_and(dynamic x, dynamic y) => x & y;

@pragma("vm:never-inline")
dynamic smi_or(dynamic x, dynamic y) => x | y;

@pragma("vm:never-inline")
dynamic smi_xor(dynamic x, dynamic y) => x ^ y;

@pragma("vm:never-inline")
dynamic smi_div(dynamic x, dynamic y) => x ~/ y;

@pragma("vm:never-inline")
dynamic smi_mod(dynamic x, dynamic y) => x % y;

@pragma("vm:never-inline")
dynamic smi_sll(dynamic x, dynamic y) => x << y;

@pragma("vm:never-inline")
dynamic smi_sra(dynamic x, dynamic y) => x >> y;

@pragma("vm:never-inline")
dynamic smi_srl(dynamic x, dynamic y) => x >>> y;

testSmi() {
  Expect.equals(7, smi_add(3, 4));
  Expect.equals(-1, smi_sub(3, 4));
  Expect.equals(12, smi_mul(3, 4));
  Expect.equals(0, smi_and(3, 4));
  Expect.equals(7, smi_or(3, 4));
  Expect.equals(7, smi_xor(3, 4));
  Expect.equals(0, smi_div(3, 4));
  Expect.equals(3, smi_mod(3, 4));
  Expect.equals(48, smi_sll(3, 4));
  Expect.equals(0, smi_sra(3, 4));
  Expect.equals(0, smi_srl(3, 4));
}

const maxSmi32 = 0x3FFFFFFF;
const maxSmi64 = 0x3FFFFFFFFFFFFFFF;
const minSmi32 = -0x80000000;
const minSmi64 = -0x8000000000000000;

testSmiDeopt() {
  Expect.equals(0x40000000, smi_add(maxSmi32, 1));
  Expect.equals(0x4000000000000000, smi_add(maxSmi64, 1));

  Expect.equals(0x40000000, smi_sub(maxSmi32, -1));
  Expect.equals(0x4000000000000000, smi_sub(maxSmi64, -1));

  Expect.equals(0x7FFFFFFE, smi_mul(maxSmi32, 2));
  Expect.equals(0x7FFFFFFFFFFFFFFE, smi_mul(maxSmi64, 2));

  Expect.equals(0x80000000, smi_div(minSmi32, -1));
  Expect.equals(0x8000000000000000, smi_div(minSmi64, -1));

  Expect.throws(() => smi_mod(minSmi32, 0));
  Expect.throws(() => smi_mod(minSmi64, 0));

  Expect.equals(0x7FFFFFFE, smi_sll(maxSmi32, 1));
  Expect.equals(0x7FFFFFFFFFFFFFFE, smi_sll(maxSmi64, 1));

  Expect.equals(0, smi_sra(maxSmi32, 65));
  Expect.equals(0, smi_sra(maxSmi64, 65));

  Expect.equals(0, smi_srl(minSmi32, 65));
  Expect.equals(0, smi_srl(minSmi64, 65));
}

main() {
  for (int i = 0; i < 200; i++) {
    testSmi();
  }

  print("=================================");

  for (int i = 0; i < 200; i++) {
    testSmiDeopt();
  }
}
