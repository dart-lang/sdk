// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  void set extendedConcreteSetter(int value) {}

  void set extendedAbstractSetter(int value);

  void set extendedConcreteImplementedSetter(int value) {}

  void set extendedAbstractImplementedSetter(int value);

  void set extendedConcreteImplementedMultipleSetter(int value) {}

  void set extendedAbstractImplementedMultipleSetter(int value);
}

class Interface1 {
  void set extendedConcreteImplementedSetter(int value) {}

  void set extendedAbstractImplementedSetter(int value) {}

  void set extendedConcreteImplementedMultipleSetter(int value) {}

  void set extendedAbstractImplementedMultipleSetter(int value) {}
}

class Interface2 {
  void set extendedConcreteImplementedMultipleSetter(int value) {}

  void set extendedAbstractImplementedMultipleSetter(int value) {}
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
