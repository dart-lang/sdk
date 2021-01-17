// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  covariant int extendedConcreteCovariantField = 0;

  abstract covariant int extendedAbstractCovariantField;

  covariant int extendedConcreteCovariantImplementedField = 0;

  abstract covariant int extendedAbstractCovariantImplementedField;

  int extendedConcreteImplementedCovariantField = 0;

  abstract int extendedAbstractImplementedCovariantField;
}

class Interface1 {
  int extendedConcreteCovariantImplementedField = 0;

  int extendedAbstractCovariantImplementedField = 0;

  covariant int extendedConcreteImplementedCovariantField = 0;

  covariant int extendedAbstractImplementedCovariantField = 0;

  covariant int implementsMultipleCovariantField1 = 0;

  int implementsMultipleCovariantField2 = 0;
}

class Interface2 {
  int implementsMultipleCovariantField1 = 0;

  covariant int implementsMultipleCovariantField2 = 0;
}

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

main() {}
