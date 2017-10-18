// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is a static warning if a method m1 overrides a method m2 and has a
// different number of required parameters.

class A {
  foo() {}
}

class B extends A {
  foo(a) {} // //# 00: static type warning
}

main() {
  B instance = new B();
  try {
    instance.foo();
  } on NoSuchMethodError catch (error) { // //# 00: continued
  } finally {}
  print("Success");
}
