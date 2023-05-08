// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks

class A {
  static func() {
    return "class A";
  }
}

class B<T> {
  doFunc() {
    T.func();
    //^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'func' isn't defined for the class 'Type'.
  }
}

main() {
  new B<A>().doFunc();
}
