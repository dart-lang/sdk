// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// uses experimental flag: --warn_no_such_type that allows compilation 
// to succeed even when types fail to resolve. in the cases below, the 
// application should still succeed at runtime.

class A {
  A(this.x);

  static type1 foo() {
     return 123;
  }

  type2 x;

  type3 myMethod(type4 param) {
    return param + x;
  }
  
  type5 get X {
    return x;
  }

  type6 bar(type7 param) {
    type8 v1 = param + 1;
    type9 v2 = v1 + X;
    return v2;
  }
}

main() {
  // static method returning unresolved type.
  Expect.equals(A.foo(), 123);

  // Field with unresolved type
  A a = new A(1);
  Expect.equals(a.x, 1);

  // Parameter with unresolved type.
  Expect.equals(a.myMethod(1), 2);

  // Getter
  Expect.equals(a.X, 1);

  // Local vars
  Expect.equals(a.bar(1), 3);
}
