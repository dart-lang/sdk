// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class ClassA {
  void method1() {}
}

extension type ExtensionTypeA(ClassA c) {
  void method1() {
    c.method1();
  }
}

extension type ExtensionTypeA1(ClassA c) implements ExtensionTypeA {}

extension type ExtensionTypeA2(ClassA c) implements ExtensionTypeA {}

class ClassB {
  void method1() {}
}

extension type ExtensionTypeB(ClassB c) {
  void method1() {
    c.method1();
  }
}

class ClassC implements ClassA, ClassB {
  void method1() {}
}

extension type ExtensionTypeC(ClassC c) {
  void method1() {
    c.method1();
  }
}

class A {}
class B {}
class C implements A, B {}

class ClassD {
  A method2() => new A();
}

class ClassE {
  B method2() => new B();
}

class ClassF implements ClassD, ClassE {
  C method2() => new C();
}

extension type ExtensionTypeD(ClassD c) implements ClassD {}

extension type ExtensionTypeE(ClassE c) implements ClassE {}

class ClassG {
  (Object?, dynamic) method3() => (0, 0);
}

class ClassH {
  (dynamic, Object?) method3() => (0, 0);
}

abstract class ClassI implements ClassG, ClassH {}

extension type ExtensionTypeG(ClassG c) implements ClassG {}

extension type ExtensionTypeH(ClassH c) implements ClassH {}

class ClassJ {
  void method4() {}
}

class ClassK {
  void set method4(int value) {}
}

extension type ExtensionTypeJ(int i) {
  void method4() {}
}

extension type ExtensionTypeK(int i) {
  void set method4(int value) {}
}

class ClassL {
  int get property => 42;
}

class ClassM {
  void set property(String value) {}
}

extension type ExtensionTypeL(int i) {
  int get property => 42;
}

extension type ExtensionTypeM(int i) {
  void set property(String value) {}
}
