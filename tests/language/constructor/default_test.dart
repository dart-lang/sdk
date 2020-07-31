// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for default constructors.

import "package:expect/expect.dart";

class A {
  A() : a = 499;

  var a;
}

class B extends A {
  B() {
    Expect.equals(499, a);
  }
}

main() {
  new B();
}
