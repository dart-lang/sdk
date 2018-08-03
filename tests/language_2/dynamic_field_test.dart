// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that ensures that fields can be accessed dynamically.

import "package:expect/expect.dart";

class A extends C {
  var a;
  var b;
}

class C {
  foo() {
    print(a); //# 01: compile-time error
    return a; //# 01: continued
  }
  bar() {
    print(b.a); //# 02: compile-time error
    return b.a; //# 02: continued
  }
}

main() {
  var a = new A();
  a.a = 1;
  a.b = a;
  Expect.equals(1, a.foo()); //# 01: continued
  Expect.equals(1, a.bar()); //# 02: continued
}
