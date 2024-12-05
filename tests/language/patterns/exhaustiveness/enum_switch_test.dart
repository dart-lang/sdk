// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E { a, b, c }

void exhaustiveSwitch(E e) {
  switch (e) /* Ok */ {
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
      break;
  }
}

const a1 = E.a;
const b1 = E.b;
const c1 = E.c;

void exhaustiveSwitchAliasedBefore(E e) {
  switch (e) /* Ok */ {
    case a1:
      print('a');
      break;
    case b1:
      print('b');
      break;
    case c1:
      print('c');
      break;
  }
}

void exhaustiveSwitchAliasedAfter(E e) {
  switch (e) /* Ok */ {
    case a2:
      print('a');
      break;
    case b2:
      print('b');
      break;
    case c2:
      print('c');
      break;
  }
}

const a2 = E.a;
const b2 = E.b;
const c2 = E.c;

void nonExhaustiveSwitch1(E e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.c'.
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitch2(E e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.b'.
    case E.a:
      print('a');
      break;
    case E.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch3(E e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.a'.
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch4(E e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.a'.
    case E.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(E e) {
  switch (e) /* Ok */ {
    case E.b:
      print('b');
      break;
    default:
      print('a|c');
      break;
  }
}

void exhaustiveNullableSwitch(E? e) {
  switch (e) /* Ok */ {
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(E? e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
      break;
  }
}

void nonExhaustiveNullableSwitch2(E? e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E?' is not exhaustively matched by the switch cases since it doesn't match 'E.b'.
    case E.a:
      print('a');
      break;
    case E.c:
      print('c');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(E e) {
  switch (e) /* Ok */ {
    case E.a:
      print('a1');
      break;
    case E.b:
      print('b');
      break;
    case E.a: // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('a2');
      break;
    case E.c:
      print('c');
      break;
  }
}

void unreachableCase2(E e) {
  switch (e) /* Non-exhaustive */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'E' is not exhaustively matched by the switch cases since it doesn't match 'E.c'.
    case E.a:
      print('a1');
      break;
    case E.b:
      print('b');
      break;
    case E.a: // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
      print('a2');
      break;
  }
}

void unreachableCase3(E e) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (e) /* Error */ {
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase4(E? e) {
  switch (e) /* Ok */ {
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
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

void unreachableCase5(E e) {
  switch (e) /* Ok */ {
    case E.a:
      print('a1');
      break;
    case E.b:
    case E.a: // Unreachable
//  ^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
    case E.c:
      print('c');
      break;
  }
}

void unreachableDefault(E e) {
  switch (e) /* Ok */ {
    case E.a:
      print('a');
      break;
    case E.b:
      print('b');
      break;
    case E.c:
      print('c');
      break;
    default: // Unreachable
//  ^^^^^^^
// [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_DEFAULT
      print('default');
      break;
  }
}
