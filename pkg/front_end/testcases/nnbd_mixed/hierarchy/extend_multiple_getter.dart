// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  int get extendedConcreteGetter => 0;

  int get extendedAbstractGetter;

  int get extendedConcreteImplementedGetter => 0;

  int get extendedAbstractImplementedGetter;

  int get extendedConcreteImplementedMultipleGetter => 0;

  int get extendedAbstractImplementedMultipleGetter;
}

class Interface1 {
  int get extendedConcreteImplementedGetter => 0;

  int get extendedAbstractImplementedGetter => 0;

  int get extendedConcreteImplementedMultipleGetter => 0;

  int get extendedAbstractImplementedMultipleGetter => 0;
}

class Interface2 {
  int get extendedConcreteImplementedMultipleGetter => 0;

  int get extendedAbstractImplementedMultipleGetter => 0;
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
