// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  int extendedConcreteField = 0;

  abstract int extendedAbstractField;

  int extendedConcreteImplementedField = 0;

  abstract int extendedAbstractImplementedField;

  int extendedConcreteImplementedMultipleField = 0;

  abstract int extendedAbstractImplementedMultipleField;
}

class Interface1 {
  int extendedConcreteImplementedField = 0;

  int extendedAbstractImplementedField = 0;

  int extendedConcreteImplementedMultipleField = 0;

  int extendedAbstractImplementedMultipleField = 0;
}

class Interface2 {
  int extendedConcreteImplementedMultipleField = 0;

  int extendedAbstractImplementedMultipleField = 0;
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
