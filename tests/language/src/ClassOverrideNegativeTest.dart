// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 8.1 Methods: It is a compile-time error if an interface method m1 overrides 
// an interface method m2 and has a different number of required parameters.

class A {
  foo() {}
}

class B extends A {
  foo(a) { }
}

main() {
  B instance = new B();
  instance.foo(1);
  print("Success");
}
