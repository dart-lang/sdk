// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int call(String str) => 499;
}

typedef int F(String str);

main() {
  var a = new A();
  if (a is Function) {
    Expect.isTrue(a is A);
  } else {
    Expect.fail("a should be a Function");
  }

  var a2 = new A();
  if (a2 is F) {
    Expect.isTrue(a2 is A);
  } else {
    Expect.fail("a2 should be an F");
  }

  Function a3 = new A();
  // Dart2Js mistakenly assumed that Function and A couldn't be related and
  // returned false for a is A.
  Expect.isTrue(a3 is A);

  F a4 = new A();
  Expect.isTrue(a4 is A);
}
