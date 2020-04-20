// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have a function overriding a field name.

class A {
  var a;
  int a() {/*@compile-error=unspecified*/
    return 1;
  }
}

class Field5Test {
  static testMain() {
    var a = new A();
  }
}

main() {
  Field5Test.testMain();
}
