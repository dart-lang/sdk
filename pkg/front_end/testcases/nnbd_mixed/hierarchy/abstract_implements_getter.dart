// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Interface {
  int get implementedConcreteGetter => 0;

  int get implementedAbstractGetter;

  int get declaredConcreteImplementsConcreteGetter => 0;

  int get declaredAbstractImplementsConcreteGetter => 0;

  int get declaredConcreteImplementsAbstractGetter;

  int get declaredAbstractImplementsAbstractGetter;
}

abstract class AbstractClass implements Interface {
  int get declaredConcreteGetter => 0;

  int get declaredAbstractGetter;

  int get declaredConcreteImplementsConcreteGetter => 0;

  int get declaredAbstractImplementsConcreteGetter;

  int get declaredConcreteImplementsAbstractGetter => 0;

  int get declaredAbstractImplementsAbstractGetter;
}

main() {}
