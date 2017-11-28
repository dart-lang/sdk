// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that calling a constructor of a class that cannot be resolved causes
// a runtime error.

import "package:expect/expect.dart";
import 'dart:math';

never() {
  Random r = new Random();
  int r1 = r.nextInt(1000);
  int r2 = r.nextInt(1000);
  int r3 = r.nextInt(1000);
  return (r1 > r3) && (r2 > r3) && (r3 > r1 + r2);
}

main() {
  if (never()) {
    // These should not produce errors because the calls are never executed.
    new A(); //        //# 01: static type warning
    new A.foo(); //    //# 02: static type warning
    new lib.A(); //    //# 03: static type warning
  }

  new A(); //        //# 04: static type warning, runtime error
  new A.foo(); //    //# 05: static type warning, runtime error
  new lib.A(); //    //# 06: static type warning, runtime error

  var ex; //                   //# 07: static type warning
  try { //                     //# 07: continued
    new A(); //                //# 07: continued
  } catch (e) { //             //# 07: continued
    ex = e; //                 //# 07: continued
  } //                         //# 07: continued
  Expect.isTrue(ex != null); //# 07: continued
}
