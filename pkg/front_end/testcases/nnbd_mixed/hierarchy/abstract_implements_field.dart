// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  int implementedConcreteField = 0;

  abstract int implementedAbstractField;

  int declaredConcreteImplementsConcreteField = 0;

  int declaredAbstractImplementsConcreteField = 0;

  abstract int declaredConcreteImplementsAbstractField;

  abstract int declaredAbstractImplementsAbstractField;
}

abstract class AbstractClass implements Interface {
  int declaredConcreteField = 0;

  abstract int declaredAbstractField;

  int declaredConcreteImplementsConcreteField = 0;

  abstract int declaredAbstractImplementsConcreteField;

  int declaredConcreteImplementsAbstractField = 0;

  abstract int declaredAbstractImplementsAbstractField;
}

main() {}
