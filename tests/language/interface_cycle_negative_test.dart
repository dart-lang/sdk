// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fail because of cycles in super interface relationship.

abstract class C implements B {

}

abstract class A implements B {

}

abstract class B implements A {

}

class InterfaceCycleNegativeTest {
  static testMain() {
  }
}

main() {
  InterfaceCycleNegativeTest.testMain();
}
