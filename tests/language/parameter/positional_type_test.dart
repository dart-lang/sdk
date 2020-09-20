// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing optional positional parameters in type tests.

main() {
  Function anyFunction;
  void acceptFunNumOptBool(void funNumOptBool(num n, [bool b])) {}
  void funNum(num n) {}
  void funNumBool(num n, bool b) {}
  void funNumOptBool(num n, [bool b = true]) {}
  void funNumOptBoolX(num n, [bool x = true]) {}

  anyFunction = funNum;
  anyFunction = funNumBool;
  anyFunction = funNumOptBool;
  anyFunction = funNumOptBoolX;
  acceptFunNumOptBool(funNumOptBool);
  acceptFunNumOptBool(funNumOptBoolX);
  acceptFunNumOptBool(funNum);
  //                  ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'void Function(num)' can't be assigned to the parameter type 'void Function(num, [bool])'.
  acceptFunNumOptBool(funNumBool);
  //                  ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'void Function(num, bool)' can't be assigned to the parameter type 'void Function(num, [bool])'.
}
