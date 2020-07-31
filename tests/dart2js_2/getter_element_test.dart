// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

class A {
  static main() {
    testOther();
    new A().testSelf();
  }

  static testOther() {
    var o = new A();
    o.instf = 0;
    o.instf += 1;
    Expect.equals(1, o.instf);
  }

  testSelf() {
    instf = 0;
    instf += 1;
    Expect.equals(1, instf);
  }

  var instf;
}

main() {
  A.main();
}
