// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

enum Enum {a, b}

void exhaustiveSwitch(({Enum a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(({Enum a, bool b}) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({Enum a, bool b})' is not exhaustively matched by the switch cases since it doesn't match '(a: Enum.b, b: false)'.
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(({Enum a, bool b}) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({Enum a, bool b})' is not exhaustively matched by the switch cases since it doesn't match '(a: Enum.a, b: false)'.
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(({Enum a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(({Enum a, bool b})? r) {
  switch (r) /* Ok */ {
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(({Enum a, bool b})? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({Enum a, bool b})?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(({Enum a, bool b})? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({Enum a, bool b})?' is not exhaustively matched by the switch cases since it doesn't match '(a: Enum.b, b: false)'.
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(({Enum a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: Enum.a, b: false):
      print('(a, false) #1');
      break;
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    case (a: Enum.a, b: false): // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(({Enum a, bool b}) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (r) /* Error */ {
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3(({Enum a, bool b})? r) {
  switch (r) /* Ok */ {
    case (a: Enum.a, b: false):
      print('(a, false)');
      break;
    case (a: Enum.b, b: false):
      print('(b, false)');
      break;
    case (a: Enum.a, b: true):
      print('(a, true)');
      break;
    case (a: Enum.b, b: true):
      print('(b, true)');
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
