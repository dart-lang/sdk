// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// An abstract class with a redirecting factory to a class with no declared
// constructor should use the implicit default constructor.

abstract class A {
  factory A() = B;
}

class B implements A {}

main() {
  var val = new A();
  Expect.equals(true, val is A);
  Expect.equals(true, val is B);
}
