// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  int extendedConcreteField = 0;

  abstract int extendedAbstractField;

  int extendedConcreteMixedInConcreteField = 0;

  abstract int extendedAbstractMixedInConcreteField;

  int extendedConcreteMixedInAbstractField = 0;

  abstract int extendedAbstractMixedInAbstractField;
}

class Mixin {
  int mixedInConcreteField = 0;

  abstract int mixedInAbstractField;

  int extendedConcreteMixedInConcreteField = 0;

  int extendedAbstractMixedInConcreteField = 0;

  abstract int extendedConcreteMixedInAbstractField;

  abstract int extendedAbstractMixedInAbstractField;
}

class ClassMixin extends Super with Mixin {}

class NamedMixin = Super with Mixin;

main() {}
