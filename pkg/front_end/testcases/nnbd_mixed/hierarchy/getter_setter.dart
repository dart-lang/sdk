// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class Super {
  String get extendedGetterDeclaredField => '';
  String get extendedGetterMixedInField => '';
  String get extendedGetterImplementedField => '';

  String get extendedGetterDeclaredSetter => '';
  String get extendedGetterMixedInSetter => '';
  String get extendedGetterImplementedSetter => '';

  final String extendedFieldDeclaredSetter = '';
  final String extendedFieldMixedInSetter = '';
  final String extendedFieldImplementedSetter = '';

  void set extendedSetterDeclaredField(int value) {}
  void set extendedSetterMixedInField(int value) {}
  void set extendedSetterImplementedField(int value) {}

  void set extendedSetterDeclaredGetter(int value) {}
  void set extendedSetterMixedInGetter(int value) {}
  void set extendedSetterImplementedGetter(int value) {}
}

abstract class Mixin {
  int extendedGetterMixedInField = 0;
  void set extendedGetterMixedInSetter(int value) {}
  void set extendedFieldMixedInSetter(int value) {}
  final String extendedSetterMixedInField = '';
  String get extendedSetterMixedInGetter => '';

  String get mixedInGetterDeclaredField => '';
  String get mixedInGetterImplementedField => '';

  String get mixedInGetterDeclaredSetter => '';
  String get mixedInGetterImplementedSetter => '';

  final String mixedInFieldDeclaredSetter = '';
  final String mixedInFieldImplementedSetter = '';

  void set mixedInSetterDeclaredField(int value) {}
  void set mixedInSetterImplementedField(int value) {}

  void set mixedInSetterDeclaredGetter(int value) {}
  void set mixedInSetterImplementedGetter(int value) {}
}

abstract class Interface1 {
  int extendedGetterImplementedField = 0;
  void set extendedGetterImplementedSetter(int value) {}
  void set extendedFieldImplementedSetter(int value) {}
  final String extendedSetterImplementedField = '';
  String get extendedSetterImplementedGetter => '';

  int mixedInGetterImplementedField = 0;
  void set mixedInGetterImplementedSetter(int value) {}
  void set mixedInFieldImplementedSetter(int value) {}
  final String mixedInSetterImplementedField = '';
  String get mixedInSetterImplementedGetter => '';

  String get implementedGetterDeclaredField => '';
  String get implementedGetterImplementedField => '';

  String get implementedGetterDeclaredSetter => '';
  String get implementedGetterImplementedSetter => '';

  final String implementedFieldDeclaredSetter = '';
  final String implementedFieldImplementedSetter = '';

  void set implementedSetterDeclaredField(int value) {}
  void set implementedSetterImplementedField(int value) {}

  void set implementedSetterDeclaredGetter(int value) {}
  void set implementedSetterImplementedGetter(int value) {}
}

abstract class Interface2 {
  int implementedGetterImplementedField = 0;
  void set implementedGetterImplementedSetter(int value) {}
  void set implementedFieldImplementedSetter(int value) {}
  final String implementedSetterImplementedField = '';
  String get implementedSetterImplementedGetter => '';
}

abstract class Class extends Super
    with Mixin
    implements Interface1, Interface2 {
  int extendedGetterDeclaredField = 0;
  void set extendedGetterDeclaredSetter(int value) {}
  void set extendedFieldDeclaredSetter(int value) {}
  final String extendedSetterDeclaredField = '';
  String get extendedSetterDeclaredGetter => '';

  int mixedInGetterDeclaredField = 0;
  void set mixedInGetterDeclaredSetter(int value) {}
  void set mixedInFieldDeclaredSetter(int value) {}
  final String mixedInSetterDeclaredField = '';
  String get mixedInSetterDeclaredGetter => '';

  int implementedGetterDeclaredField = 0;
  void set implementedGetterDeclaredSetter(int value) {}
  void set implementedFieldDeclaredSetter(int value) {}
  final String implementedSetterDeclaredField = '';
  String get implementedSetterDeclaredGetter => '';

  String get declaredGetterDeclaredSetter => '';
  void set declaredGetterDeclaredSetter(int value) {}

  final String declaredFieldDeclaredSetter = '';
  void set declaredFieldDeclaredSetter(int value) {}
}

main() {}
