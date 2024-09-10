// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum Enum {a, b}

void exhaustiveSwitch((Enum, bool) r) {
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
  }
}

void nonExhaustiveSwitch1((Enum, bool) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)' is not exhaustively matched by the switch cases since it doesn't match '(Enum.b, false)'.
    case (Enum.a, false):
      print('(a, false)');
      break;
    case (Enum.a, true):
      print('(a, true)');
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
// [cfe] The type '(Enum, bool)' is not exhaustively matched by the switch cases since it doesn't match '(Enum.a, false)'.
    case (Enum.b, false):
      print('(b, false)');
      break;
    case (Enum.a, true):
      print('(a, true)');
      break;
    case (Enum.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault((Enum, bool) r) {
  switch (r) /* Ok */ {
    case (Enum.a, false):
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch((Enum, bool)? r) {
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
  }
}

void nonExhaustiveNullableSwitch2((Enum, bool)? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(Enum, bool)?' is not exhaustively matched by the switch cases since it doesn't match '(Enum.b, false)'.
    case (Enum.a, false):
      print('(a, false)');
      break;
    case (Enum.a, true):
      print('(a, true)');
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
      print('(a, false) #1');
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
    case (Enum.a, false): // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2((Enum, bool) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (r) /* Error */ {
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
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3((Enum, bool)? r) {
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
    case null:
      print('null1');
      break;
    case null: // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('null2');
      break;
  }
}

void unreachableDefault((Enum, bool) r) {
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
    default: // Unreachable
//  ^^^^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_DEFAULT
      print('default');
      break;
  }
}

void unreachableDefaultNotAlwaysExhaustive((Enum, int) r) {
  // If the type being switched on isn't "always exhaustive", no
  // `UNREACHABLE_SWITCH_DEFAULT` warning is reported, because flow analysis
  // might not understand that the switch cases fully exhaust the switch, so
  // removing the default clause might result in spurious errors.
  switch (r) /* Ok */ {
    case (Enum.a, 0):
      print('(a, 0)');
      break;
    case (Enum.b, 0):
      print('(b, 0)');
      break;
    case (Enum.a, _):
      print('(a, nonzero)');
      break;
    case (Enum.b, _):
      print('(b, nonzero)');
      break;
    default: // Unreachable
      print('default');
      break;
  }
}
