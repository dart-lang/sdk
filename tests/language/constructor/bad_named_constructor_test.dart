// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A() {}
  WrongName.foo() {}
//^^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.INVALID_CONSTRUCTOR_NAME
// [cfe] The name of a constructor must match the name of the enclosing class.
}

main() {
  new A();
}
