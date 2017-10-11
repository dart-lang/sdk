// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that the ?. operator cannot be used with "super".

class B {
  B();
  B.namedConstructor();
  var field = 1;
  method() => 1;
}

class C extends B {
  C()
    : super?.namedConstructor() //# 01: compile-time error
  ;

  test() {
    super?.field = 1; //# 02: compile-time error
    super?.field += 1; //# 03: compile-time error
    super?.field ??= 1; //# 04: compile-time error
    super?.field; //# 05: compile-time error
    1 * super?.field; //# 06: compile-time error
    -super?.field; //# 07: compile-time error
    ~super?.field; //# 08: compile-time error
    !super?.field; //# 09: compile-time error
    --super?.field; //# 10: compile-time error
    ++super?.field; //# 11: compile-time error
    super?.method(); //# 12: compile-time error
    1 * super?.method(); //# 13: compile-time error
    -super?.method(); //# 14: compile-time error
    ~super?.method(); //# 15: compile-time error
    !super?.method(); //# 16: compile-time error
    --super?.method(); //# 17: compile-time error
    ++super?.method(); //# 18: compile-time error
  }
}

main() {
  new C().test();
}
