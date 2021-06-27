// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class AbstractSuper {
  final int extendedConcreteField = 0;

  abstract final int extendedAbstractField;

  final int declaredConcreteExtendsConcreteField = 0;

  final int declaredAbstractExtendsConcreteField = 0;

  abstract final int declaredConcreteExtendsAbstractField;

  abstract final int declaredAbstractExtendsAbstractField;
}

abstract class AbstractClass extends AbstractSuper {
  final int declaredConcreteField = 0;

  abstract final int declaredAbstractField;

  final int declaredConcreteExtendsConcreteField = 0;

  abstract final int declaredAbstractExtendsConcreteField;

  final int declaredConcreteExtendsAbstractField = 0;

  abstract final int declaredAbstractExtendsAbstractField;
}

main() {}
