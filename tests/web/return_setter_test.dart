// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  int? foo;

  static int? invocations;

  static bar() {
    Expect.equals(0, invocations);
    invocations = invocations! + 1;
    return 2;
  }
}

main() {
  A.invocations = 0;

  int a = (new A().foo = 2);
  Expect.equals(2, a);

  a = (new A().foo = A.bar());
  Expect.equals(2, a);
}
