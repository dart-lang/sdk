// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=
// VMOptions=--compile_all

// Exercises language constructs that require compile time constants

// Initialize with different literal types
final b = true;
final s = "apple";
final i = 1;
final d = 3.3;
final h = 0xf;
final n = null;
final aList = const[1, 2, 3]; // array literal
final aMap = const { "1": "one", "2": "banana" }; // map literal

final INT_LIT = 5;
final INT_LIT_REF = INT_LIT;
final DOUBLE_LIT = 1.5;
final BOOL_LIT = true;
final STRING_LIT = "Hello";

final BOP1_0 = INT_LIT + 1;
final BOP1_1 = 1 + INT_LIT;
final BOP1_2 = INT_LIT - 1;
final BOP1_3 = 1 - INT_LIT;
final BOP1_4 = INT_LIT * 1;
final BOP1_5 = 1 * INT_LIT;
final BOP1_6 = INT_LIT / 1;
final BOP1_7 = 1 / INT_LIT;
final BOP2_0 = DOUBLE_LIT + 1.5;
final BOP2_1 = 1.5 + DOUBLE_LIT;
final BOP2_2 = DOUBLE_LIT - 1.5;
final BOP2_3 = 1.5 - DOUBLE_LIT;
final BOP2_4 = DOUBLE_LIT * 1.5;
final BOP2_5 = 1.5 * DOUBLE_LIT;
final BOP2_6 = DOUBLE_LIT / 1.5;
final BOP2_7 = 1.5 / DOUBLE_LIT;
final BOP3_0 = 2 < INT_LIT;
final BOP3_1 = INT_LIT < 2;
final BOP3_2 = 2 > INT_LIT;
final BOP3_3 = INT_LIT > 2;
final BOP3_4 = 2 < DOUBLE_LIT;
final BOP3_5 = DOUBLE_LIT < 2;
final BOP3_6 = 2 > DOUBLE_LIT;
final BOP3_7 = DOUBLE_LIT > 2;
final BOP3_8 = 2 <= INT_LIT;
final BOP3_9 = INT_LIT <= 2;
final BOP3_10 = 2 >= INT_LIT;
final BOP3_11 = INT_LIT >= 2;
final BOP3_12 = 2.0 <= DOUBLE_LIT;
final BOP3_13 = DOUBLE_LIT <= 2.0;
final BOP3_14 = 2.0 >= DOUBLE_LIT;
final BOP3_15 = DOUBLE_LIT >= 2;
final BOP4_0 = 5 % INT_LIT;
final BOP4_1 = INT_LIT % 5;
final BOP4_2 = 5.0 % DOUBLE_LIT;
final BOP4_3 = DOUBLE_LIT % 5.0;
final BOP5_0 = 0x80 & 0x04;
final BOP5_1 = 0x80 | 0x04;
final BOP5_2 = 0x80 << 0x04;
final BOP5_3 = 0x80 >> 0x04;
final BOP5_4 = 0x80 ~/ 0x04;
final BOP5_5 = 0x80 ^ 0x04;
final BOP6 = BOOL_LIT && true;
final BOP7 = false || BOOL_LIT;
final BOP8 = STRING_LIT == "World!";
final BOP9 = "Hello" != STRING_LIT;
final BOP10 = INT_LIT === INT_LIT_REF;
final BOP11 = BOOL_LIT !== true;

// Multiple binary expressions
final BOP20 = 1 * INT_LIT / 3 + INT_LIT + 9;

// Parenthised expressions
final BOP30 = ( 1 > 2 );
final BOP31 = (1 * 2) + 3;
final BOP32= 3 + (1 * 2);

// Unary expressions
final UOP1_0 = !BOOL_LIT;
final UOP1_1 = BOOL_LIT || !true;
final UOP1_2 = !BOOL_LIT || true;
final UOP1_3 = !(BOOL_LIT && true);
final UOP2_0 = ~0xf0;
final UOP2_1 = ~INT_LIT;
final UOP2_2 = ~INT_LIT & 123;
final UOP2_3 = ~(INT_LIT | 0xff);
final UOP3_0 = -0xf0;
final UOP3_1 = -INT_LIT;
final UOP3_2 = -INT_LIT + 123;
final UOP3_3 = -(INT_LIT * 0xff);
final UOP3_4 = -0xf0;
final UOP3_5 = -DOUBLE_LIT;
final UOP3_6 = -DOUBLE_LIT + 123;
final UOP3_7 = -(DOUBLE_LIT * 0xff);

class A {
  const A();
  static final a = const A(); // Assignment from Constant constructor OK
}

main () {
}
