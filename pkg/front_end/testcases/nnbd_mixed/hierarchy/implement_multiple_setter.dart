// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface1 {
  void set implementMultipleSetter(int i) {}

  void set declareConcreteImplementMultipleSetter(int i) {}

  void set declareAbstractImplementMultipleSetter(int i) {}
}

class Interface2 {
  void set implementMultipleSetter(int i) {}

  void set declareConcreteImplementMultipleSetter(int i) {}

  void set declareAbstractImplementMultipleSetter(int i) {}
}

class ConcreteClass implements Interface1, Interface2 {
  void set declareConcreteImplementMultipleSetter(int i) {}

  void set declareAbstractImplementMultipleSetter(int i);
}

abstract class AbstractClass implements Interface1, Interface2 {
  void set declareConcreteImplementMultipleSetter(int i) {}

  void set declareAbstractImplementMultipleSetter(int i);
}

class ConcreteSub extends AbstractClass {}

main() {}
