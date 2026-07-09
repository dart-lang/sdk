// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that extension type erasure is not performed
// when checking the type argument of a relational pattern.

extension type const E(int representation) implements Object {}

class A {
  bool operator ==(covariant int other) => true;
  bool operator <(int other) => true;
  bool operator <=(int other) => true;
  bool operator >(int other) => true;
  bool operator >=(int other) => true;
}

class B {
  bool operator ==(covariant E other) => true;
  bool operator <(E other) => true;
  bool operator <=(E other) => true;
  bool operator >(E other) => true;
  bool operator >=(E other) => true;
}

const E0 = E(0);

test() {
  if (A() case == E0) {}
  //              ^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'E' can't be assigned to the parameter type 'int'.
  if (A() case != E0) {}
  //              ^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'E' can't be assigned to the parameter type 'int'.
  if (A() case > E0) {}
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'E' can't be assigned to the parameter type 'int'.
  if (A() case >= E0) {}
  //              ^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'E' can't be assigned to the parameter type 'int'.
  if (A() case < E0) {}
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'E' can't be assigned to the parameter type 'int'.
  if (A() case <= E0) {}
  //              ^^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'E' can't be assigned to the parameter type 'int'.
  if (B() case == 0) {}
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'E'.
  if (B() case != 0) {}
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'E'.
  if (B() case > 0) {}
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'E'.
  if (B() case >= 0) {}
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'E'.
  if (B() case < 0) {}
  //             ^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'E'.
  if (B() case <= 0) {}
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.RELATIONAL_PATTERN_OPERAND_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'E'.
}
