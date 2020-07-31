// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final a;
  A(this.a); // Not const.
  const A.five() : a = 5;
}

class B extends A {
  final b;
  B(x)
      : b = x + 1,
        super(x);

  // Const constructor cannot call non-const super constructor.

}

class C extends A {
  C() : super(0);
  // Implicit call to non-const constructor A(x).

}

main() {

  var b1 = new B(0);

}
