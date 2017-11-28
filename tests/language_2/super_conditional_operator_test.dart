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
    : super?.namedConstructor() //# 01: syntax error
  ;

  test() {
    super?.field = 1; //# 02: syntax error
    super?.field += 1; //# 03: syntax error
    super?.field ??= 1; //# 04: syntax error
    super?.field; //# 05: syntax error
    1 * super?.field; //# 06: syntax error
    -super?.field; //# 07: syntax error
    ~super?.field; //# 08: syntax error
    !super?.field; //# 09: syntax error
    --super?.field; //# 10: syntax error
    ++super?.field; //# 11: syntax error
    super?.method(); //# 12: syntax error
    1 * super?.method(); //# 13: syntax error
    -super?.method(); //# 14: syntax error
    ~super?.method(); //# 15: syntax error
    !super?.method(); //# 16: syntax error
    --super?.method(); //# 17: syntax error
    ++super?.method(); //# 18: syntax error
  }
}

main() {
  new C().test();
}
