// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  final int extendedConcreteField = 0;

  abstract final int extendedAbstractField;

  final int extendedConcreteMixedInConcreteField = 0;

  abstract final int extendedAbstractMixedInConcreteField;

  final int extendedConcreteMixedInAbstractField = 0;

  abstract final int extendedAbstractMixedInAbstractField;
}

class Mixin {
  final int mixedInConcreteField = 0;

  abstract final int mixedInAbstractField;

  final int extendedConcreteMixedInConcreteField = 0;

  final int extendedAbstractMixedInConcreteField = 0;

  abstract final int extendedConcreteMixedInAbstractField;

  abstract final int extendedAbstractMixedInAbstractField;
}

class ClassMixin extends Super with Mixin {}

class NamedMixin = Super with Mixin;

main() {}
