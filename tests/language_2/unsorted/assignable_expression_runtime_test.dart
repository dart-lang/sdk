// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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




  C.field = 0;




  variable = [1, 2, 3];
  variable[0] = 0;
  (variable)[0] = 0;




  C.field = [1, 2, 3];




  var a = 0;




  // Neat palindrome expression. x is assignable, ((x)) is not.

}
