// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It is a static compile time error if a method m1 overrides a method m2 and has a
// different number of required parameters.

class A {
  foo() {}
}

class B extends A {
  /*@compile-error=unspecified*/ foo(a) {} 
}

main() {
  new B().foo(42);
}
