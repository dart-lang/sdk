// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the ?. operator cannot be used for forwarding "this"
// constructors.

class B {
  B();
  B.namedConstructor();
  var field = 1;
  method() => 1;

  B.forward()
    : this?.namedConstructor() //# 01: compile-time error
  ;

  test() {
    this?.field = 1;
    this?.field += 1;
    this?.field;
    this?.method();
  }
}

main() {
  new B.forward().test();
}
