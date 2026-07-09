// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  C.oneArg(Object x) : assert(x);
  //                          ^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_EXPRESSION
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
  C.twoArgs(Object x, Object y) : assert(x, y);
  //                                     ^
  // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_EXPRESSION
  // [cfe] A value of type 'Object' can't be assigned to a variable of type 'bool'.
}

void main() {
  Object b = true;
  new C.oneArg(b);
  new C.twoArgs(false, b);
}
