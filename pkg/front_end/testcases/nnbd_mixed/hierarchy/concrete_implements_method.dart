// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface {
  void implementedConcreteMethod() {}

  void implementedAbstractMethod();

  void declaredConcreteImplementsConcreteMethod() {}

  void declaredAbstractImplementsConcreteMethod() {}

  void declaredConcreteImplementsAbstractMethod();

  void declaredAbstractImplementsAbstractMethod();
}

class ConcreteClass implements Interface {
  void declaredConcreteMethod() {}

  void declaredAbstractMethod();

  void declaredConcreteImplementsConcreteMethod() {}

  void declaredAbstractImplementsConcreteMethod();

  void declaredConcreteImplementsAbstractMethod() {}

  void declaredAbstractImplementsAbstractMethod();
}

main() {}
