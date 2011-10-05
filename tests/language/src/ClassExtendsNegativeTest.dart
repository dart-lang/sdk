// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check fails because class extends from interface.

interface InterfaceA {

}

class ClassA extends InterfaceA {

}

class ClassExtendsNegativeTest {
  static testMain() {
  }
}

main() {
  ClassExtendsNegativeTest.testMain();
}
