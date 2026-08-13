// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  void set x1(covariant A value) {}
  void set x2(A value) {}
  void set x3(covariant A value) {}
  void set x4(A value) {}
  void set x5(covariant A value) {}
  void set x6(covariant B value) {}
}

class D extends C {
  void set x1(B value) {} // Ok because covariant is inherited
  void set x2(covariant B value) {} // Ok because covariant
  void set x3(covariant B value) {} // Ok because covariant
  void set x4(B value) {} // Not covariant
  void set x5(covariant String value) {}
  void set x6(covariant A value) {} // Always ok
}

main() {}
