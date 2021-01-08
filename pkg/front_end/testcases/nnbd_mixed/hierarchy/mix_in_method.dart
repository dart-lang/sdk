// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void extendedConcreteMethod() {}

  void extendedAbstractMethod();

  void extendedConcreteMixedInConcreteMethod() {}

  void extendedAbstractMixedInConcreteMethod();

  void extendedConcreteMixedInAbstractMethod() {}

  void extendedAbstractMixedInAbstractMethod();
}

class Mixin {
  void mixedInConcreteMethod() {}

  void mixedInAbstractMethod();

  void extendedConcreteMixedInConcreteMethod() {}

  void extendedAbstractMixedInConcreteMethod() {}

  void extendedConcreteMixedInAbstractMethod();

  void extendedAbstractMixedInAbstractMethod();
}

class ClassMixin extends Super with Mixin {}

class NamedMixin = Super with Mixin;

main() {}
