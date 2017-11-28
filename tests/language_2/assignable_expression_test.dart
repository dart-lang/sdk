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
  (variable) = 0; //   //# 01: syntax error
  (variable)++; //     //# 02: syntax error
  ++(variable); //     //# 03: syntax error

  C.field = 0;
  (C.field) = 0; //  //# 11: syntax error
  (C.field)++; //    //# 12: syntax error
  ++(C.field); //    //# 13: syntax error

  variable = [1, 2, 3];
  variable[0] = 0;
  (variable)[0] = 0;
  (variable[0]) = 0; //   //# 21: syntax error
  (variable[0])++; //     //# 22: syntax error
  ++(variable[0]); //     //# 23: syntax error

  C.field = [1, 2, 3];
  (C.field[0]) = 0; //  //# 31: syntax error
  (C.field[0])++; //    //# 32: syntax error
  ++(C.field[0]); //    //# 33: syntax error

  var a = 0;
  (a) = 0; //  //# 41: syntax error
  (a)++; //    //# 42: syntax error
  ++(a); //    //# 43: syntax error

  // Neat palindrome expression. x is assignable, ((x)) is not.
  var funcnuf = (x) => ((x))=((x)) <= (x); // //# 50: syntax error
}
