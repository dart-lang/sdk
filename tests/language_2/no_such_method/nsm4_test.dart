// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for compile-time errors for member access on classes that inherit a
// user defined noSuchMethod.

import "package:expect/expect.dart";

class Mock {
  noSuchMethod(i) => 42;
}

abstract class Foo {
  int foo();
}

class Valid extends Mock implements Foo {}

main() {
  Expect.equals(new Valid().foo(), 42);
}
