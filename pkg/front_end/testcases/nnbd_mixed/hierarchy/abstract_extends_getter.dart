// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class AbstractSuper {
  int get extendedConcreteGetter => 0;

  int get extendedAbstractGetter;

  int get declaredConcreteExtendsConcreteGetter => 0;

  int get declaredAbstractExtendsConcreteGetter => 0;

  int get declaredConcreteExtendsAbstractGetter;

  int get declaredAbstractExtendsAbstractGetter;
}

abstract class AbstractClass extends AbstractSuper {
  int get declaredConcreteGetter => 0;

  int get declaredAbstractGetter;

  int get declaredConcreteExtendsConcreteGetter => 0;

  int get declaredAbstractExtendsConcreteGetter;

  int get declaredConcreteExtendsAbstractGetter => 0;

  int get declaredAbstractExtendsAbstractGetter;
}

main() {}
