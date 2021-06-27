// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void extendedConcreteMixedInAbstractMethod() {}
  void extendedConcreteMixedInConcreteMethod() {}
  void extendedConcreteMixedInAbstractImplementedMethod(int i) {}
  void extendedConcreteMixedInConcreteImplementedMethod(int i) {}
}

class Interface {
  void extendedConcreteMixedInAbstractImplementedMethod(covariant num i) {}
  void extendedConcreteMixedInConcreteImplementedMethod(covariant num i) {}
}

mixin Mixin {
  void extendedConcreteMixedInAbstractMethod();
  void extendedConcreteMixedInConcreteMethod() {}
  void extendedConcreteMixedInAbstractImplementedMethod(int i);
  void extendedConcreteMixedInConcreteImplementedMethod(int i) {}
}

class Class = Super with Mixin implements Interface;

class Sub extends Class {
  void test() {
    extendedConcreteMixedInAbstractMethod();
    super.extendedConcreteMixedInAbstractMethod();
    extendedConcreteMixedInConcreteMethod();
    super.extendedConcreteMixedInConcreteMethod();

    extendedConcreteMixedInAbstractImplementedMethod(0);
    super.extendedConcreteMixedInAbstractImplementedMethod(0);
    extendedConcreteMixedInConcreteImplementedMethod(0);
    super.extendedConcreteMixedInConcreteImplementedMethod(0);
  }
}

main() {}
