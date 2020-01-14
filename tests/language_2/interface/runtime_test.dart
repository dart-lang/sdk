// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing Interfaces.

abstract class Ai {
  int foo();
}

abstract class Bi implements Ai {

}

abstract class Simple implements Ai {}

abstract class Aai {}

abstract class Abi {}

abstract class Bar {}

abstract class Foo implements Bar {}

abstract class Baz implements Bar, Foo {}

abstract class InterfaceTest implements Ai, Aai, Abi, Baz, Bi {
  var f;

  InterfaceTest() {}
  int foo() {
    return 1;
  }

  // intentionally unimplemented methods
  beta(); // Abstract.
  String beta1(); // Abstract.
  String beta2(double d); // Abstract.
}

main() {

}
