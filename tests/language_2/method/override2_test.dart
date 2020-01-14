// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that an overriding method has compatible parameters.

abstract class I {
  m({a, b});
}

abstract class J extends I {}

abstract class K extends J {
  m({c, d}); // //# 00: compile-time error
}

class C implements I {
  m({a, b}) {
    print("$a $b");
  }
}

class D
    extends C // //# 01: compile-time error
    implements I // //# 02: compile-time error
    implements J // //# 03: compile-time error
{
  m({c, d}) {
    print("$c $d");
  }
}

int main() {
  var c = new C();
  c.m(a: "hello", b: "world");
  var d = new D();
  d.m(c: "hello", d: "world");
}
