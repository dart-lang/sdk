// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void extendedMethodDeclaredGetter() {}
  void extendedMethodDeclaredSetter() {}
  void extendedMethodDeclaredField() {}
  int get extendedGetterDeclaredMethod => 0;
  void set extendedSetterDeclaredMethod(int value) {}
  int extendedFieldDeclaredMethod = 0;

  void extendedMethodMixedInGetter() {}
  void extendedMethodMixedInSetter() {}
  void extendedMethodMixedInField() {}
  int get extendedGetterMixedInMethod => 0;
  void set extendedSetterMixedInMethod(int value) {}
  int extendedFieldMixedInMethod = 0;

  void extendedMethodImplementedGetter() {}
  void extendedMethodImplementedSetter() {}
  void extendedMethodImplementedField() {}
  int get extendedGetterImplementedMethod => 0;
  void set extendedSetterImplementedMethod(int value) {}
  int extendedFieldImplementedMethod = 0;
}

class Mixin {
  void mixedInMethodDeclaredGetter() {}
  void mixedInMethodDeclaredSetter() {}
  void mixedInMethodDeclaredField() {}
  int get mixedInGetterDeclaredMethod => 0;
  void set mixedInSetterDeclaredMethod(int value) {}
  int mixedInFieldDeclaredMethod = 0;

  void mixedInMethodImplementedGetter() {}
  void mixedInMethodImplementedSetter() {}
  void mixedInMethodImplementedField() {}
  int get mixedInGetterImplementedMethod => 0;
  void set mixedInSetterImplementedMethod(int value) {}
  int mixedInFieldImplementedMethod = 0;

  int get extendedMethodMixedInGetter => 0;
  void set extendedMethodMixedInSetter(int value) {}
  int extendedMethodMixedInField = 0;
  void extendedGetterMixedInMethod() {}
  void extendedSetterMixedInMethod() {}
  void extendedFieldMixedInMethod() {}
}

class Interface1 {
  void implementedMethodDeclaredGetter() {}
  void implementedMethodDeclaredSetter() {}
  void implementedMethodDeclaredField() {}
  int get implementedGetterDeclaredMethod => 0;
  void set implementedSetterDeclaredMethod(int value) {}
  int implementedFieldDeclaredMethod = 0;

  void implementedMethodImplementedGetter() {}
  void implementedMethodImplementedSetter() {}
  void implementedMethodImplementedField() {}
  int get implementedGetterImplementedMethod => 0;
  void set implementedSetterImplementedMethod(int value) {}
  int implementedFieldImplementedMethod = 0;

  int get extendedMethodImplementedGetter => 0;
  void set extendedMethodImplementedSetter(int value) {}
  int extendedMethodImplementedField = 0;
  void extendedGetterImplementedMethod() {}
  void extendedSetterImplementedMethod() {}
  void extendedFieldImplementedMethod() {}

  int get mixedInMethodImplementedGetter => 0;
  void set mixedInMethodImplementedSetter(int value) {}
  int mixedInMethodImplementedField = 0;
  void mixedInGetterImplementedMethod() {}
  void mixedInSetterImplementedMethod() {}
  void mixedInFieldImplementedMethod() {}
}

class Interface2 {
  int get implementedMethodImplementedGetter => 0;
  void set implementedMethodImplementedSetter(int value) {}
  int implementedMethodImplementedField = 0;
  void implementedGetterImplementedMethod() {}
  void implementedSetterImplementedMethod() {}
  void implementedFieldImplementedMethod() {}
}

abstract class Class extends Super
    with Mixin
    implements Interface1, Interface2 {
  int get extendedMethodDeclaredGetter => 0;
  void set extendedMethodDeclaredSetter(int value) {}
  int extendedMethodDeclaredField = 0;
  void extendedGetterDeclaredMethod() {}
  void extendedSetterDeclaredMethod() {}
  void extendedFieldDeclaredMethod() {}

  int get mixedInMethodDeclaredGetter => 0;
  void set mixedInMethodDeclaredSetter(int value) {}
  int mixedInMethodDeclaredField = 0;
  void mixedInGetterDeclaredMethod() {}
  void mixedInSetterDeclaredMethod() {}
  void mixedInFieldDeclaredMethod() {}

  int get implementedMethodDeclaredGetter => 0;
  void set implementedMethodDeclaredSetter(int value) {}
  int implementedMethodDeclaredField = 0;
  void implementedGetterDeclaredMethod() {}
  void implementedSetterDeclaredMethod() {}
  void implementedFieldDeclaredMethod() {}

  void declaredMethodAndSetter() {}
  void set declaredMethodAndSetter(int value) {}
}

main() {}
