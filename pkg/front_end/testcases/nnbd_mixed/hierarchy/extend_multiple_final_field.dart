// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  final int extendedConcreteField = 0;

  abstract final int extendedAbstractField;

  final int extendedConcreteImplementedField = 0;

  abstract final int extendedAbstractImplementedField;

  final int extendedConcreteImplementedMultipleField = 0;

  abstract final int extendedAbstractImplementedMultipleField;
}

class Interface1 {
  final int extendedConcreteImplementedField = 0;

  final int extendedAbstractImplementedField = 0;

  final int extendedConcreteImplementedMultipleField = 0;

  final int extendedAbstractImplementedMultipleField = 0;
}

class Interface2 {
  final int extendedConcreteImplementedMultipleField = 0;

  final int extendedAbstractImplementedMultipleField = 0;
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
