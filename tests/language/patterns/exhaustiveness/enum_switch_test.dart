// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

enum Enum { a, b, c }

void exhaustiveSwitch(Enum e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

const a1 = Enum.a;
const b1 = Enum.b;
const c1 = Enum.c;

void exhaustiveSwitchAliasedBefore(Enum e) {
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

void exhaustiveSwitchAliasedAfter(Enum e) {
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

const a2 = Enum.a;
const b2 = Enum.b;
const c2 = Enum.c;

void nonExhaustiveSwitch1(Enum e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum' is not exhaustively matched by the switch cases.
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitch2(Enum e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum' is not exhaustively matched by the switch cases.
    case Enum.a:
      print('a');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch3(Enum e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum' is not exhaustively matched by the switch cases.
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveSwitch4(Enum e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum' is not exhaustively matched by the switch cases.
    case Enum.b:
      print('b');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(Enum e) {
  switch (e) /* Ok */ {
    case Enum.b:
      print('b');
      break;
    default:
      print('a|c');
      break;
  }
}

void exhaustiveNullableSwitch(Enum? e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(Enum? e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum?' is not exhaustively matched by the switch cases.
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void nonExhaustiveNullableSwitch2(Enum? e) {
  switch (e) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum?' is not exhaustively matched by the switch cases.
    case Enum.a:
      print('a');
      break;
    case Enum.c:
      print('c');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(Enum e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a1');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.a: // Unreachable
//  ^
// [cfe] This case is covered by the previous cases.
      print('a2');
      break;
    case Enum.c:
      print('c');
      break;
  }
}

void unreachableCase2(Enum e) {
  switch (e) /* Non-exhaustive */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH
//        ^
// [cfe] The type 'Enum' is not exhaustively matched by the switch cases.
    case Enum.a:
      print('a1');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.a: // Unreachable
//  ^
// [cfe] This case is covered by the previous cases.
      print('a2');
      break;
  }
}

void unreachableCase3(Enum e) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (e) /* Error */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase4(Enum? e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a');
      break;
    case Enum.b:
      print('b');
      break;
    case Enum.c:
      print('c');
      break;
    case null:
      print('null1');
      break;
    case null: // Unreachable
//  ^
// [cfe] This case is covered by the previous cases.
      print('null2');
      break;
  }
}

void unreachableCase5(Enum e) {
  switch (e) /* Ok */ {
    case Enum.a:
      print('a1');
      break;
    case Enum.b:
    case Enum.a: // Unreachable
//  ^
// [cfe] This case is covered by the previous cases.
    case Enum.c:
      print('c');
      break;
  }
}
