// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface {
  void set implementedConcreteSetter(int value) {}

  void set implementedAbstractSetter(int value);

  void set declaredConcreteImplementsConcreteSetter(int value) {}

  void set declaredAbstractImplementsConcreteSetter(int value) {}

  void set declaredConcreteImplementsAbstractSetter(int value);

  void set declaredAbstractImplementsAbstractSetter(int value);
}

class ConcreteClass implements Interface {
  void set declaredConcreteSetter(int value) {}

  void set declaredAbstractSetter(int value);

  void set declaredConcreteImplementsConcreteSetter(int value) {}

  void set declaredAbstractImplementsConcreteSetter(int value);

  void set declaredConcreteImplementsAbstractSetter(int value) {}

  void set declaredAbstractImplementsAbstractSetter(int value);
}

main() {}
