// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
abstract class Super {
  void concreteExtendsConcreteMixin() {}
  void concreteExtendsAbstractMixin() {}
  void abstractExtendsConcreteMixin();
  void abstractExtendsAbstractMixin();
}

abstract class MixinClass {
  void concreteExtendsConcreteMixin() {}
  void concreteExtendsAbstractMixin();
  void concreteMixin() {}
  void abstractExtendsConcreteMixin() {}
  void abstractExtendsAbstractMixin();
  void abstractMixin();
}

mixin Mixin {
  void concreteExtendsConcreteMixin() {}
  void concreteExtendsAbstractMixin();
  void concreteMixin() {}
  void abstractExtendsConcreteMixin() {}
  void abstractExtendsAbstractMixin();
  void abstractMixin();
}

abstract class ClassEqMixinClass = Super with MixinClass;

abstract class ClassExtendsMixinClass extends Super with MixinClass {}

abstract class ClassEqMixin = Super with Mixin;

abstract class ClassExtendsMixin extends Super with Mixin {}

abstract class SubclassEqMixinClass extends ClassEqMixinClass {
  method() {
    concreteExtendsConcreteMixin();
    concreteExtendsAbstractMixin();
    concreteMixin();
    abstractExtendsConcreteMixin();
    abstractExtendsAbstractMixin();
    abstractMixin();
    super.concreteExtendsConcreteMixin();
    super.concreteExtendsAbstractMixin();
    super.concreteMixin();
    super.abstractExtendsConcreteMixin();
  }
}

abstract class SubclassExtendsMixinClass extends ClassExtendsMixinClass {
  method() {
    concreteExtendsConcreteMixin();
    concreteMixin();
    concreteExtendsAbstractMixin();
    abstractExtendsConcreteMixin();
    abstractExtendsAbstractMixin();
    abstractMixin();
    super.concreteExtendsConcreteMixin();
    super.concreteExtendsAbstractMixin();
    super.concreteMixin();
    super.abstractExtendsConcreteMixin();
  }
}

abstract class SubclassEqMixin extends ClassEqMixin {
  method() {
    concreteExtendsConcreteMixin();
    concreteExtendsAbstractMixin();
    concreteMixin();
    abstractExtendsConcreteMixin();
    abstractExtendsAbstractMixin();
    abstractMixin();
    super.concreteExtendsConcreteMixin();
    super.concreteExtendsAbstractMixin();
    super.concreteMixin();
    super.abstractExtendsConcreteMixin();
  }
}

abstract class SubclassExtendsMixin extends ClassExtendsMixin {
  method() {
    concreteExtendsConcreteMixin();
    concreteExtendsAbstractMixin();
    concreteMixin();
    abstractExtendsConcreteMixin();
    abstractExtendsAbstractMixin();
    abstractMixin();
    super.concreteExtendsConcreteMixin();
    super.concreteExtendsAbstractMixin();
    super.concreteMixin();
    super.abstractExtendsConcreteMixin();
  }
}

main() {}
