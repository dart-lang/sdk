// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  Object? m(covariant int a);
}

abstract class B {
  dynamic m(covariant num a);
}

abstract class C {
  void m(num a);
}

abstract class D implements A {
  Object? m(int a);
}

abstract class E implements B {
  dynamic m(num a);
}

abstract class F {
  Object? m(int a);
}

abstract class G implements C {
  m(a);
}

abstract class H implements D, E, F, C {}

abstract class I implements D {
  m(a);
}

abstract class J implements H {
  m(a);
}

abstract class K implements I, E, G {}

abstract class L implements K {
  m(a);
}

main() {}
