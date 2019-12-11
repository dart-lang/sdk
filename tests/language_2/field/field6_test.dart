// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test to catch error reporting bugs in class fields declarations.
// Should be an error because we have a getter overriding a function name.

class A {
  int a() { // //# 00: ok
    return 1;// //# 00: ok
  }// //# 00: ok

  int get a {// //# 00: compile-time error
    return 10;// //# 00: ok
  }// //# 00: ok

  int get a {// //# 01: ok
    return 10;// //# 01: ok
  }// //# 01: ok

  int a() {// //# 01: compile-time error
    return 1;// //# 01: ok
  }// //# 01: ok

}

class Field6Test {
  static testMain() {
    var a = new A();
  }
}

main() {
  Field6Test.testMain();
}
