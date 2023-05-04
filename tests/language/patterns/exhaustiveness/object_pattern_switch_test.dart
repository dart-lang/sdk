// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records,sealed-class

enum Enum {a, b}

sealed class A {
  final Enum a;
  bool get b;
  A(this.a);
}

class B extends A {
  final bool b;
  B(super.a, this.b);
}

void exhaustiveSwitch(A r) {
  switch (r) /* Ok */ {
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(A r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'B(a: Enum.b, b: false)'.
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(A r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'B(a: Enum.a, b: false)'.
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A r) {
  switch (r) /* Ok */ {
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? r) {
  switch (r) /* Ok */ {
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A?' is not exhaustively matched by the switch cases since it doesn't match 'B(a: Enum.b, b: false)'.
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(A r) {
  switch (r) /* Ok */ {
    case A(a: Enum.a, b: false):
      print('A(a, false) #1');
      break;
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    case A(a: Enum.a, b: false): // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(A r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (r) /* Error */ {
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3(A? r) {
  switch (r) /* Ok */ {
    case A(a: Enum.a, b: false):
      print('A(a, false)');
      break;
    case A(a: Enum.b, b: false):
      print('A(b, false)');
      break;
    case A(a: Enum.a, b: true):
      print('A(a, true)');
      break;
    case A(a: Enum.b, b: true):
      print('A(b, true)');
      break;
    case null:
      print('null #1');
      break;
    case null: // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('null #2');
      break;
  }
}
