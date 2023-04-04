// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that exhaustiveness handles sealed type hierarchies that aren't strict
// trees.

// SharedOptions=--enable-experiment=patterns,sealed-class

// Create a class hierarchy like:
//
//     (A)
//     / \
//   (B) (C)
//   / \ / \
//  D   E   F
sealed class A {}

sealed class B implements A {}

sealed class C implements A {}

class D implements B {}

class E implements B, C {}

class F implements C {}

test(A a) {
  // OK: All leaves.
  switch (a) {
    case D _:
      print('D');
    case E _:
      print('E');
    case F _:
      print('F');
  }

  // OK: One leaf, one branch.
  switch (a) {
    case B _:
      print('B');
    case F _:
      print('F');
  }

  switch (a) {
    case C _:
      print('C');
    case D _:
      print('D');
  }

  // OK: Both branches.
  switch (a) {
    case B _:
      print('B');
    case C _:
      print('C');
  }

  // OK: Root.
  switch (a) {
    case A _:
      print('A');
  }

  // Missing leaf.
  switch (a) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'D()'.
    case E _:
      print('E');
    case F _:
      print('F');
  }

  switch (a) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'E()'.
    case D _:
      print('D');
    case F _:
      print('F');
  }

  switch (a) {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'F()'.
    case D _:
      print('D');
    case E _:
      print('E');
  }

  // Branch covers leaves.
  switch (a) {
    case B _:
      print('B');
    case D _:
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('D');
    case E _:
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('E');
    case F _:
      print('F');
  }
}
