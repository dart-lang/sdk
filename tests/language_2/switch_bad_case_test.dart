// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test reporting a compile-time error if case expressions do not all have
// the same type or are of type double.

import "package:expect/expect.dart";

void main() {
  Expect.equals("IV", caesarSays(4));
  Expect.equals(null, caesarSays(2));
  Expect.equals(null, archimedesSays(3.14));
}

caesarSays(n) {
  switch (n) {
    case 1:
      return "I";
    case 4:
      return "IV";
    case "M": //        //# 01: compile-time error
      return 1000; //   //# 01: continued
  }
  return null;
}

archimedesSays(n) {
  switch (n) { //       //# 02: continued
    case 3.14: //       //# 02: compile-time error
      return "Pi"; //   //# 02: continued
    case 2.71828: //    //# 02: continued
      return "Huh?"; // //# 02: continued
  } //                  //# 02: continued
  return null;
}
