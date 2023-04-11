// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,records

enum Enum {a, b}

void exhaustiveSwitch1((Enum, bool) r) {
  switch (r) /* Ok */ {
    case (Enum.a, var b):
      print('(a, *)');
      break;
    case (Enum.b, bool b):
      print('(b, *)');
      break;
  }
}

void exhaustiveSwitch2((Enum, bool) r) {
  switch (r) /* Ok */ {
    case (Enum.a, true):
      print('(a, false)');
      break;
    case (Enum a, bool b):
      print('(*, *)');
      break;
  }
}

void nonExhaustiveSwitch1((Enum, bool) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)' is not exhaustively matched by the switch cases since it doesn't match '(Enum.b, false)'.
    case (Enum.a, var b):
      print('(a, *)');
      break;
    case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2((Enum, bool) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)' is not exhaustively matched by the switch cases since it doesn't match '(Enum.b, true)'.
    case (var a, false):
      print('(*, false)');
      break;
    case (Enum.a, true):
      print('(a, true)');
      break;
  }
}

void nonExhaustiveSwitch3((Enum, bool) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)' is not exhaustively matched by the switch cases since it doesn't match '(Enum.b, true)'.
    case (Enum a, false):
      print('(*, false)');
      break;
    case (Enum.a, true):
      print('(a, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault((Enum, bool) r) {
  switch (r) /* Ok */ {
    case (Enum.a, var b):
      print('(a, *)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch((Enum, bool)? r) {
  switch (r) /* Ok */ {
    case (Enum.a, var b):
      print('(a, *)');
      break;
    case (Enum.b, bool b):
      print('(b, *)');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1((Enum, bool)? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case (Enum a, bool b):
      print('(*, *)');
      break;
  }
}

void nonExhaustiveNullableSwitch2((Enum, bool)? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)?' is not exhaustively matched by the switch cases since it doesn't match '(Enum.a, true)'.
    case (Enum a, false):
      print('(*, false)');
      break;
    case (Enum.b, true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1((Enum, bool) r) {
  switch (r) /* Ok */ {
    case (Enum.a, false):
      print('(a, false)');
      break;
    case (Enum.b, false):
      print('(b, false)');
      break;
    case (Enum.a, true):
      print('(a, true)');
      break;
    case (Enum.b, true):
      print('(b, true)');
      break;
    case (Enum a, bool b): // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('(*, *)');
      break;
  }
}

void unreachableCase2((Enum, bool) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (r) /* Error */ {
    case (Enum a, bool b):
      print('(*, *)');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3((Enum, bool)? r) {
  switch (r) /* Ok */ {
    case (var a, var b):
      print('(*, *)');
      break;
    case null:
      print('null1');
      break;
    case null: // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('null2');
      break;
  }
}
