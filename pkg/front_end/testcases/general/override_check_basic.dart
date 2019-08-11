// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  void f1(A x) {}
  void f2([A x]) {}
  void f3({A x}) {}
  A f4() {}
}

class D extends C {
  void f1(Object x) {} // Ok
  void f2([Object x]) {} // Ok
  void f3({Object x}) {} // Ok
  B f4() {} // Ok
}

class E extends C {
  void f1(B x) {}
  void f2([B x]) {}
  void f3({B x}) {}
  Object f4() {}
}

main() {}
