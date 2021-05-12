// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Confirm that redirecting named constructors are properly resolved.
//
// Note that this test may become invalid due to http://dartbug.com/5940.

class C {
  var x;
  C() {
    x = 1;
  }
  C.C() {
    x = 2;
  }
  C.redirecting() : this.C();
}

main() {
  var c = new C.redirecting();
  Expect.equals(c.x, 2);
}
