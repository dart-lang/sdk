// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  void extendedConcreteCovariantMethod(covariant int i) {}

  void extendedAbstractCovariantMethod(covariant int i);

  void extendedConcreteCovariantImplementedMethod(covariant int i) {}

  void extendedAbstractCovariantImplementedMethod(covariant int i);

  void extendedConcreteImplementedCovariantMethod(int i) {}

  void extendedAbstractImplementedCovariantMethod(int i);
}

class Interface1 {
  void extendedConcreteCovariantImplementedMethod(int i) {}

  void extendedAbstractCovariantImplementedMethod(int i) {}

  void extendedConcreteImplementedCovariantMethod(covariant int i) {}

  void extendedAbstractImplementedCovariantMethod(covariant int i) {}

  void implementsMultipleCovariantMethod1(covariant int i) {}

  void implementsMultipleCovariantMethod2(int i) {}
}

class Interface2 {
  void implementsMultipleCovariantMethod1(int i) {}

  void implementsMultipleCovariantMethod2(covariant int i) {}
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
