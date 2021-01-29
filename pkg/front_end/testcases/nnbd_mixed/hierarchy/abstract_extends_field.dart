// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class AbstractSuper {
  int extendedConcreteField = 0;

  abstract int extendedAbstractField;

  int declaredConcreteExtendsConcreteField = 0;

  int declaredAbstractExtendsConcreteField = 0;

  abstract int declaredConcreteExtendsAbstractField;

  abstract int declaredAbstractExtendsAbstractField;
}

abstract class AbstractClass extends AbstractSuper {
  int declaredConcreteField = 0;

  abstract int declaredAbstractField;

  int declaredConcreteExtendsConcreteField = 0;

  abstract int declaredAbstractExtendsConcreteField;

  int declaredConcreteExtendsAbstractField = 0;

  abstract int declaredAbstractExtendsAbstractField;
}

main() {}
