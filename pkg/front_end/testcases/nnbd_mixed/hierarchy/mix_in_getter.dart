// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  int get extendedConcreteGetter => 0;

  int get extendedAbstractGetter;

  int get extendedConcreteMixedInConcreteGetter => 0;

  int get extendedAbstractMixedInConcreteGetter;

  int get extendedConcreteMixedInAbstractGetter => 0;

  int get extendedAbstractMixedInAbstractGetter;
}

class Mixin {
  int get mixedInConcreteGetter => 0;

  int get mixedInAbstractGetter;

  int get extendedConcreteMixedInConcreteGetter => 0;

  int get extendedAbstractMixedInConcreteGetter => 0;

  int get extendedConcreteMixedInAbstractGetter;

  int get extendedAbstractMixedInAbstractGetter;
}

class ClassMixin extends Super with Mixin {}

class NamedMixin = Super with Mixin;

main() {}
