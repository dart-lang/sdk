// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  static void extendedStaticDeclaredInstanceMethod() {}
  void extendedInstanceDeclaredStaticMethod() {}

  static void set extendedStaticDeclaredInstanceSetter(int value) {}
  void set extendedInstanceDeclaredStaticSetter(int value) {}

  static int get extendedStaticGetterDeclaredInstanceSetter => 0;
  int get extendedInstanceGetterDeclaredStaticSetter => 0;

  static void set extendedStaticSetterDeclaredInstanceGetter(int value) {}
  void set extendedInstanceSetterDeclaredStaticGetter(int value) {}

  static void extendedStaticMixedInInstanceMethod() {}
  void extendedInstanceMixedInStaticMethod() {}

  static void extendedStaticImplementedInstanceMethod() {}
  void extendedInstanceImplementedStaticMethod() {}
}

mixin Mixin {
  static void mixedInStaticDeclaredInstanceMethod() {}
  void mixedInInstanceDeclaredStaticMethod() {}

  static void mixedInStaticImplementedInstanceMethod() {}
  void mixedInInstanceImplementedStaticMethod() {}

  void extendedStaticMixedInInstanceMethod() {}
  static void extendedInstanceMixedInStaticMethod() {}
}

class Interface {
  static void implementedStaticDeclaredInstanceMethod() {}
  void implementedInstanceDeclaredStaticMethod() {}

  static void set implementedStaticDeclaredInstanceSetter(int value) {}
  void set implementedInstanceDeclaredStaticSetter(int value) {}

  static int get implementedStaticGetterDeclaredInstanceSetter => 0;
  int get implementedInstanceGetterDeclaredStaticSetter => 0;

  static void set implementedStaticSetterDeclaredInstanceGetter(int value) {}
  void set implementedInstanceSetterDeclaredStaticGetter(int value) {}

  void extendedStaticImplementedInstanceMethod() {}
  static void extendedInstanceImplementedStaticMethod() {}

  void mixedInStaticImplementedInstanceMethod() {}
  static void mixedInInstanceImplementedStaticMethod() {}
}

abstract class Class extends Super with Mixin implements Interface {
  void extendedStaticDeclaredInstanceMethod() {}
  static void extendedInstanceDeclaredStaticMethod() {}

  void set extendedStaticDeclaredInstanceSetter(int value) {}
  static void set extendedInstanceDeclaredStaticSetter(int value) {}

  void set extendedStaticGetterDeclaredInstanceSetter(int value) {}
  static void set extendedInstanceGetterDeclaredStaticSetter(int value) {}

  int get extendedStaticSetterDeclaredInstanceGetter => 0;
  static int get extendedInstanceSetterDeclaredStaticGetter => 0;

  void mixedInStaticDeclaredInstanceMethod() {}
  static void mixedInInstanceDeclaredStaticMethod() {}

  void implementedStaticDeclaredInstanceMethod() {}
  static void implementedInstanceDeclaredStaticMethod() {}

  void set implementedStaticDeclaredInstanceSetter(int value) {}
  static void set implementedInstanceDeclaredStaticSetter(int value) {}

  void set implementedStaticGetterDeclaredInstanceSetter(int value) {}
  static void set implementedInstanceGetterDeclaredStaticSetter(int value) {}

  int get implementedStaticSetterDeclaredInstanceGetter => 0;
  static int get implementedInstanceSetterDeclaredStaticGetter => 0;
}

main() {}
