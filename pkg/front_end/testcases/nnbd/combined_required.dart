// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void method1({required int a}) {}
  void method2({int? a, required int b}) {}
}

class B {
  void method1({required covariant int a}) {}
  void method2({covariant int? a, required int b}) {}
}

class C extends A implements B {}

class D extends C {
  void method1({required covariant int a}) {}
  void method2({covariant int? a, required int b}) {}
}

main() {}
