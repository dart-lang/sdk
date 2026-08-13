// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void method(dynamic a);
}

abstract class B {
  void method(covariant num a);
}

abstract class C {
  void method(covariant int a);
}

abstract class D1 implements A, B, C {}

abstract class D2 implements A, B {}

abstract class D3 implements B, C {}

abstract class D4 implements C, B {}

abstract class D5 implements A, C {}

abstract class E {
  void method(num a);
}

abstract class F {
  void method(covariant int a);
}

abstract class G1 implements E, F {}

abstract class G2 implements F, E {}

main() {}
