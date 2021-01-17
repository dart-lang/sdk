// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  void extendedConcreteMethod() {}

  void extendedAbstractMethod();

  void extendedConcreteImplementedMethod() {}

  void extendedAbstractImplementedMethod();

  void extendedConcreteImplementedMultipleMethod() {}

  void extendedAbstractImplementedMultipleMethod();
}

class Interface1 {
  void extendedConcreteImplementedMethod() {}

  void extendedAbstractImplementedMethod() {}

  void extendedConcreteImplementedMultipleMethod() {}

  void extendedAbstractImplementedMultipleMethod() {}
}

class Interface2 {
  void extendedConcreteImplementedMultipleMethod() {}

  void extendedAbstractImplementedMultipleMethod() {}
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
