// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {a, b}

void exhaustiveSwitch(({E a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch1(({E a, bool b}) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({E a, bool b})' is not exhaustively matched by the switch cases since it doesn't match '(a: E.b, b: false)'.
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitch2(({E a, bool b}) r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({E a, bool b})' is not exhaustively matched by the switch cases since it doesn't match '(a: E.a, b: false)'.
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(({E a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(({E a, bool b})? r) {
  switch (r) /* Ok */ {
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(({E a, bool b})? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({E a, bool b})?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
  }
}

void nonExhaustiveNullableSwitch2(({E a, bool b})? r) {
  switch (r) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type '({E a, bool b})?' is not exhaustively matched by the switch cases since it doesn't match '(a: E.b, b: false)'.
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(({E a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: E.a, b: false):
      print('(a, false) #1');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
    case (a: E.a, b: false): // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('(a, false) #2');
      break;
  }
}

void unreachableCase2(({E a, bool b}) r) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (r) /* Error */ {
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3(({E a, bool b})? r) {
  switch (r) /* Ok */ {
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
    case null:
      print('null #1');
      break;
    case null: // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('null #2');
      break;
  }
}

void unreachableDefault(({E a, bool b}) r) {
  switch (r) /* Ok */ {
    case (a: E.a, b: false):
      print('(a, false)');
      break;
    case (a: E.b, b: false):
      print('(b, false)');
      break;
    case (a: E.a, b: true):
      print('(a, true)');
      break;
    case (a: E.b, b: true):
      print('(b, true)');
      break;
    default: // Unreachable
//  ^^^^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_DEFAULT
      print('default');
      break;
  }
}

void unreachableDefaultNotAlwaysExhaustive(({E a, int i}) r) {
  // If the type being switched on isn't "always exhaustive", no
  // `UNREACHABLE_SWITCH_DEFAULT` warning is reported, because flow analysis
  // might not understand that the switch cases fully exhaust the switch, so
  // removing the default clause might result in spurious errors.
  switch (r) /* Ok */ {
    case (a: E.a, i: 0):
      print('(a, 0)');
      break;
    case (a: E.b, i: 0):
      print('(b, 0)');
      break;
    case (a: E.a, i: _):
      print('(a, nonzero)');
      break;
    case (a: E.b, i: _):
      print('(b, nonzero)');
      break;
    default: // Unreachable
      print('default');
      break;
  }
}
