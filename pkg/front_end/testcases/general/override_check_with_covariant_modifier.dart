// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  void f1(covariant A x) {}
  void f2(A x) {}
  void f3(covariant A x) {}
  void f4(A x) {}
  void f5(covariant A x) {}
  void f6(covariant B x) {}
}

class D extends C {
  void f1(B x) {} // Ok because covariant is inherited
  void f2(covariant B x) {} // Ok because covariant
  void f3(covariant B x) {} // Ok because covariant
  void f4(B x) {} // Not covariant
  void f5(covariant String x) {}
  void f6(covariant A x) {} // Always ok
}

main() {}
