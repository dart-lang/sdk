// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {a, b}

void exhaustiveSwitch((E, bool) r) {
  switch (r) /* Ok */ {
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1((E, bool) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(E, bool)' is not exhaustively matched by the switch cases since it doesn't match '(E.b, false)'.
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2((E, bool) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(E, bool)' is not exhaustively matched by the switch cases since it doesn't match '(E.a, false)'.
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault((E, bool) r) {
  switch (r) /* Ok */ {
    case (E.a, false):
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch((E, bool)? r) {
  switch (r) /* Ok */ {
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1((E, bool)? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(E, bool)?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2((E, bool)? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '(E, bool)?' is not exhaustively matched by the switch cases since it doesn't match '(E.b, false)'.
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1((E, bool) r) {
  switch (r) /* Ok */ {
    case (E.a, false):
      print('(a, false) #1');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
    case (E.a, false): // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2((E, bool) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (r) /* Error */ {
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3((E, bool)? r) {
  switch (r) /* Ok */ {
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
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

void unreachableDefault((E, bool) r) {
  switch (r) /* Ok */ {
    case (E.a, false):
      print('(a, false)');
      break;
    case (E.b, false):
      print('(b, false)');
      break;
    case (E.a, true):
      print('(a, true)');
      break;
    case (E.b, true):
      print('(b, true)');
      break;
    default: // Unreachable
//  ^^^^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_DEFAULT
      print('default');
      break;
  }
}

void unreachableDefaultNotAlwaysExhaustive((E, int) r) {
  // If the type being switched on isn't "always exhaustive", no
  // `UNREACHABLE_SWITCH_DEFAULT` warning is reported, because flow analysis
  // might not understand that the switch cases fully exhaust the switch, so
  // removing the default clause might result in spurious errors.
  switch (r) /* Ok */ {
    case (E.a, 0):
      print('(a, 0)');
      break;
    case (E.b, 0):
      print('(b, 0)');
      break;
    case (E.a, _):
      print('(a, nonzero)');
      break;
    case (E.b, _):
      print('(b, nonzero)');
      break;
    default: // Unreachable
      print('default');
      break;
  }
}
