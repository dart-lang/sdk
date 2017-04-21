// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that it is a compile-time error to have a redirection in a
// non-factory constructor.

class Foo {
  Foo()
  = Bar //# 01: compile-time error
  ;
}

class Bar extends Foo {
  factory Bar() => null;
}

main() {
  Expect.isTrue(new Foo() is Foo);
  Expect.isFalse(new Foo() is Bar);
}
