// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that parameter default values are disallowed in a redirecting factory.

import "package:expect/expect.dart";

class A {
  A(this.a, [this.b = 0]);
  factory A.f(int a) = A;



  int a;
  int b;
}

main() {
  var x = new A.f(42);
  Expect.equals(x.a, 42);
  Expect.equals(x.b, 0);


}
