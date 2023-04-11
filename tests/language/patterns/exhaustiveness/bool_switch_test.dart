// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=patterns

void exhaustiveSwitch(bool b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
  }
}

const t1 = true;
const f1 = false;

void exhaustiveSwitchAliasedBefore(bool b) {
  switch (b) /* Ok */ {
    case t1:
      print('true');
      break;
    case f1:
      print('false');
      break;
  }
}

void exhaustiveSwitchAliasedAfter(bool b) {
  switch (b) /* Ok */ {
    case t2:
      print('true');
      break;
    case f2:
      print('false');
      break;
  }
}

const t2 = true;
const f2 = false;

void nonExhaustiveSwitch1(bool b) {
  switch (b) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'bool' is not exhaustively matched by the switch cases since it doesn't match 'false'.
    case true:
      print('true');
      break;
  }
}

void nonExhaustiveSwitch2(bool b) {
  switch (b) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'bool' is not exhaustively matched by the switch cases since it doesn't match 'true'.
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveSwitchWithDefault(bool b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    default:
      print('default');
      break;
  }
}

void exhaustiveNullableSwitch(bool? b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
    case null:
      print('null');
      break;
  }
}

void nonExhaustiveNullableSwitch1(bool? b) {
  switch (b) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'bool?' is not exhaustively matched by the switch cases since it doesn't match 'null'.
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
  }
}

void nonExhaustiveNullableSwitch2(bool? b) {
  switch (b) /* Error */ {
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_STATEMENT
//        ^
// [cfe] The type 'bool?' is not exhaustively matched by the switch cases since it doesn't match 'false'.
    case true:
      print('true');
      break;
    case null:
      print('null');
      break;
  }
}

void unreachableCase1(bool b) {
  switch (b) /* Ok */ {
    case true:
      print('true1');
      break;
    case false:
      print('false');
      break;
    case true: // Unreachable
//  ^^^^
// [analyzer] HINT.UNREACHABLE_SWITCH_CASE
      print('true2');
      break;
  }
}

void unreachableCase2(bool b) {
  // TODO(johnniwinther): Should we avoid the unreachable error here?
  switch (b) /* Error */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
      break;
    case null: // Unreachable
      print('null');
      break;
  }
}

void unreachableCase3(bool? b) {
  switch (b) /* Ok */ {
    case true:
      print('true');
      break;
    case false:
      print('false');
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
