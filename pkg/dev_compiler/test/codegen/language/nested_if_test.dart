// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart2Js had problems with nested ifs inside loops.

import "package:expect/expect.dart";

foo(x, a) {
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*------- Avoid inlining ----------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  /*---------------------------------------------*/
  for (int i = 0; i < 10; i++) {
    if (x) {
      if (!x) a = [];
      a.add(3);
    }
  }
  return a;
}

main() {
  var a = foo(true, []);
  Expect.equals(10, a.length);
  Expect.equals(3, a[0]);
}
