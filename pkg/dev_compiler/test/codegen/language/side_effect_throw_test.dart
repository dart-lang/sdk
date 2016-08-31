// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class B {
  static var x;
  operator <<(other) {
    x = other;
    return 33;
  }
}

class A {
  get _m => new B();
  opshl(n) {
    // 'n' must be a number, but we are not allowed to throw before we have
    // evaluated _m << 499.
    return (_m << 499) | (2 - n);
  }
}

main() {
  var a = new A();
  Expect.throws(() => a.opshl("string"));
  Expect.equals(499, B.x);
}
