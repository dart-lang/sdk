// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This checks that it is possible to have a method named negate as
// well as unary- operator.

class Foo {
  operator -() => 42;
  negate() => 87;
}

main() {
  Expect.equals(42, -new Foo());
  Expect.equals(87, new Foo().negate());
}
