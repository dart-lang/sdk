// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns,sealed-class,records

sealed class A {}
class B extends A {}
class C extends A {}
class D extends A {}

enum Enum {a, b}

void exhaustiveSwitch1(A a) {
  switch (a) /* Ok */ {
    case B b:
      print('B');
      break;
    case C c:
      print('C');
      break;
    case D d:
      print('D');
      break;
  }
}

void exhaustiveSwitch2(A a) {
  switch (a) /* Ok */ {
    case B b:
      print('B');
      break;
    case A a:
      print('A');
      break;
  }
}

void nonExhaustiveSwitch1(A a) {
  switch (a) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'D()'.
    case B b:
      print('B');
      break;
    case C c:
      print('C');
      break;
  }
}

void nonExhaustiveSwitch2(A a) {
  switch (a) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'B()'.
    case C c:
      print('C');
      break;
    case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitch3(A a) {
  switch (a) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A' is not exhaustively matched by the switch cases since it doesn't match 'C()'.
    case B b:
      print('B');
      break;
    case D d:
      print('D');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(A a) {
  switch (a) /* Ok */ {
    case B b:
      print('B');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(A? a) {
  switch (a) /* Ok */ {
    case B b:
      print('B');
      break;
    case C c:
      print('C');
      break;
    case D d:
      print('D');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(A? a) {
  switch (a) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case A a:
      print('A');
      break;
  }
}

void nonExhaustiveNullableSwitch2(A? a) {
  switch (a) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'A?' is not exhaustively matched by the switch cases since it doesn't match 'D()'.
    case B b:
      print('B');
      break;
    case C c:
      print('C');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(A a) {
  switch (a) /* Ok */ {
    case B b:
      print('B');
      break;
    case C c:
      print('C');
      break;
    case D d:
      print('D');
      break;
    case A a: // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('A');
      break;
  }
}

void unreachableCase2(A a) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (a) /* Error */ {
    case A a:
      print('A');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3(A? a) {
  switch (a) /* Ok */ {
    case A a:
      print('A');
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
