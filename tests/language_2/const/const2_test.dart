// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--compile_all

// Exercises language constructs that require compile time constants

// Initialize with different literal types
const b = true;
const s = "apple";
const i = 1;
const d = 3.3;
const h = 0xf;
const n = null;
const aList = const [1, 2, 3]; // array literal
const aMap = const {"1": "one", "2": "banana"}; // map literal

const INT_LIT = 5;
const INT_LIT_REF = INT_LIT;
const DOUBLE_LIT = 1.5;
const BOOL_LIT = true;
const STRING_LIT = "Hello";

const BOP1_0 = INT_LIT + 1;
const BOP1_1 = 1 + INT_LIT;
const BOP1_2 = INT_LIT - 1;
const BOP1_3 = 1 - INT_LIT;
const BOP1_4 = INT_LIT * 1;
const BOP1_5 = 1 * INT_LIT;
const BOP1_6 = INT_LIT / 1;
const BOP1_7 = 1 / INT_LIT;
const BOP2_0 = DOUBLE_LIT + 1.5;
const BOP2_1 = 1.5 + DOUBLE_LIT;
const BOP2_2 = DOUBLE_LIT - 1.5;
const BOP2_3 = 1.5 - DOUBLE_LIT;
const BOP2_4 = DOUBLE_LIT * 1.5;
const BOP2_5 = 1.5 * DOUBLE_LIT;
const BOP2_6 = DOUBLE_LIT / 1.5;
const BOP2_7 = 1.5 / DOUBLE_LIT;
const BOP3_0 = 2 < INT_LIT;
const BOP3_1 = INT_LIT < 2;
const BOP3_2 = 2 > INT_LIT;
const BOP3_3 = INT_LIT > 2;
const BOP3_4 = 2 < DOUBLE_LIT;
const BOP3_5 = DOUBLE_LIT < 2;
const BOP3_6 = 2 > DOUBLE_LIT;
const BOP3_7 = DOUBLE_LIT > 2;
const BOP3_8 = 2 <= INT_LIT;
const BOP3_9 = INT_LIT <= 2;
const BOP3_10 = 2 >= INT_LIT;
const BOP3_11 = INT_LIT >= 2;
const BOP3_12 = 2.0 <= DOUBLE_LIT;
const BOP3_13 = DOUBLE_LIT <= 2.0;
const BOP3_14 = 2.0 >= DOUBLE_LIT;
const BOP3_15 = DOUBLE_LIT >= 2;
const BOP4_0 = 5 % INT_LIT;
const BOP4_1 = INT_LIT % 5;
const BOP4_2 = 5.0 % DOUBLE_LIT;
const BOP4_3 = DOUBLE_LIT % 5.0;
const BOP5_0 = 0x80 & 0x04;
const BOP5_1 = 0x80 | 0x04;
const BOP5_2 = 0x80 << 0x04;
const BOP5_3 = 0x80 >> 0x04;
const BOP5_4 = 0x80 ~/ 0x04;
const BOP5_5 = 0x80 ^ 0x04;
const BOP6 = BOOL_LIT && true;
const BOP7 = false || BOOL_LIT;
const BOP8 = STRING_LIT == "World!";
const BOP9 = "Hello" != STRING_LIT;
const BOP10 = INT_LIT == INT_LIT_REF;
const BOP11 = BOOL_LIT != true;

// Multiple binary expressions
const BOP20 = 1 * INT_LIT / 3 + INT_LIT + 9;

// Parenthised expressions
const BOP30 = (1 > 2);
const BOP31 = (1 * 2) + 3;
const BOP32 = 3 + (1 * 2);

// Unary expressions
const UOP1_0 = !BOOL_LIT;
const UOP1_1 = BOOL_LIT || !true;
const UOP1_2 = !BOOL_LIT || true;
const UOP1_3 = !(BOOL_LIT && true);
const UOP2_0 = ~0xf0;
const UOP2_1 = ~INT_LIT;
const UOP2_2 = ~INT_LIT & 123;
const UOP2_3 = ~(INT_LIT | 0xff);
const UOP3_0 = -0xf0;
const UOP3_1 = -INT_LIT;
const UOP3_2 = -INT_LIT + 123;
const UOP3_3 = -(INT_LIT * 0xff);
const UOP3_4 = -0xf0;
const UOP3_5 = -DOUBLE_LIT;
const UOP3_6 = -DOUBLE_LIT + 123;
const UOP3_7 = -(DOUBLE_LIT * 0xff);

class A {
  const A();
  static const a = const A(); // Assignment from Constant constructor OK
}

main() {}
