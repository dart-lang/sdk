// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface1 {
  int implementMultipleField = 0;

  int declareConcreteImplementMultipleField = 0;

  int declareAbstractImplementMultipleField = 0;
}

class Interface2 {
  int implementMultipleField = 0;

  int declareConcreteImplementMultipleField = 0;

  int declareAbstractImplementMultipleField = 0;
}

class ConcreteClass implements Interface1, Interface2 {
  int declareConcreteImplementMultipleField = 0;

  abstract int declareAbstractImplementMultipleField;
}

abstract class AbstractClass implements Interface1, Interface2 {
  int declareConcreteImplementMultipleField = 0;

  abstract int declareAbstractImplementMultipleField;
}

class ConcreteSub extends AbstractClass {}

main() {}
