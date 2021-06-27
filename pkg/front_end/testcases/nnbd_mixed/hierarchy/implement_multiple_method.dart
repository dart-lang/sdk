// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface1 {
  void implementMultipleMethod() {}

  void declareConcreteImplementMultipleMethod() {}

  void declareAbstractImplementMultipleMethod() {}
}

class Interface2 {
  void implementMultipleMethod() {}

  void declareConcreteImplementMultipleMethod() {}

  void declareAbstractImplementMultipleMethod() {}
}

class ConcreteClass implements Interface1, Interface2 {
  void declareConcreteImplementMultipleMethod() {}

  void declareAbstractImplementMultipleMethod();
}

abstract class AbstractClass implements Interface1, Interface2 {
  void declareConcreteImplementMultipleMethod() {}

  void declareAbstractImplementMultipleMethod();
}

class ConcreteSub extends AbstractClass {}

main() {}
