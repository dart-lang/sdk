// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void extendedConcreteDeclaredConcreteMethod() {}

  void extendedAbstractDeclaredConcreteMethod();

  void extendedConcreteDeclaredAbstractMethod() {}

  void extendedAbstractDeclaredAbstractMethod();

  void extendedConcreteImplementedDeclaredConcreteMethod() {}

  void extendedAbstractImplementedDeclaredConcreteMethod();

  void extendedConcreteImplementedDeclaredAbstractMethod() {}

  void extendedAbstractImplementedDeclaredAbstractMethod();
}

class Interface {
  void implementedDeclaredConcreteMethod() {}

  void implementedDeclaredAbstractMethod() {}

  void extendedConcreteImplementedDeclaredConcreteMethod() {}

  void extendedAbstractImplementedDeclaredConcreteMethod() {}

  void extendedConcreteImplementedDeclaredAbstractMethod() {}

  void extendedAbstractImplementedDeclaredAbstractMethod() {}
}

class Class extends Super implements Interface {
  void extendedConcreteDeclaredConcreteMethod() {}

  void extendedAbstractDeclaredConcreteMethod() {}

  void extendedConcreteDeclaredAbstractMethod();

  void extendedAbstractDeclaredAbstractMethod();

  void implementedDeclaredConcreteMethod() {}

  void implementedDeclaredAbstractMethod();

  void extendedConcreteImplementedDeclaredConcreteMethod() {}

  void extendedAbstractImplementedDeclaredConcreteMethod() {}

  void extendedConcreteImplementedDeclaredAbstractMethod();

  void extendedAbstractImplementedDeclaredAbstractMethod();
}

main() {}
