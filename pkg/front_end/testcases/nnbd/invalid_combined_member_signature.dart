// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void method1(C c) {}
  void method2(int a, int b) {}
}

class B {
  void method1(Unresolved c) {}
  void method2(int a) {}
}

class C {}

abstract class D implements A, B {}

main() {}
