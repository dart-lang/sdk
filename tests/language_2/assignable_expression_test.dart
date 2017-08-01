// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to detect syntactically illegal left-hand-side (assignable)
// expressions.

class C {
  static dynamic field = 0;
}

dynamic variable = 0;

main() {
  variable = 0;
  (variable) = 0; //   //# 01: compile-time error
  (variable)++; //     //# 02: compile-time error
  ++(variable); //     //# 03: compile-time error

  C.field = 0;
  (C.field) = 0; //  //# 11: compile-time error
  (C.field)++; //    //# 12: compile-time error
  ++(C.field); //    //# 13: compile-time error

  variable = [1, 2, 3];
  variable[0] = 0;
  (variable)[0] = 0;
  (variable[0]) = 0; //   //# 21: compile-time error
  (variable[0])++; //     //# 22: compile-time error
  ++(variable[0]); //     //# 23: compile-time error

  C.field = [1, 2, 3];
  (C.field[0]) = 0; //  //# 31: compile-time error
  (C.field[0])++; //    //# 32: compile-time error
  ++(C.field[0]); //    //# 33: compile-time error

  var a = 0;
  (a) = 0; //  //# 41: compile-time error
  (a)++; //    //# 42: compile-time error
  ++(a); //    //# 43: compile-time error

  // Neat palindrome expression. x is assignable, ((x)) is not.
  var funcnuf = (x) => ((x))=((x)) <= (x); // //# 50: compile-time error
}
