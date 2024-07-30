// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void set extendedConcreteSetter(int i) {}

  void set extendedAbstractSetter(int i);

  void set extendedConcreteMixedInConcreteSetter(int i) {}

  void set extendedAbstractMixedInConcreteSetter(int i);

  void set extendedConcreteMixedInAbstractSetter(int i) {}

  void set extendedAbstractMixedInAbstractSetter(int i);
}

mixin class Mixin {
  void set mixedInConcreteSetter(int i) {}

  void set mixedInAbstractSetter(int i);

  void set extendedConcreteMixedInConcreteSetter(int i) {}

  void set extendedAbstractMixedInConcreteSetter(int i) {}

  void set extendedConcreteMixedInAbstractSetter(int i);

  void set extendedAbstractMixedInAbstractSetter(int i);
}

class ClassMixin extends Super with Mixin {}

class NamedMixin = Super with Mixin;

main() {}
