// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  Class.constructorAndMethod();
  void constructorAndMethod() {}

  factory Class.factoryAndMethod() => new Class.constructorAndMethod();
  void factoryAndMethod() {}

  factory Class.redirectingFactoryAndMethod() = Class.constructorAndMethod;
  void redirectingFactoryAndMethod() {}

  Class.constructorAndField();
  dynamic constructorAndField;

  factory Class.factoryAndField() => new Class.constructorAndField();
  dynamic factoryAndField;

  factory Class.redirectingFactoryAndField() = Class.constructorAndField;
  dynamic redirectingFactoryAndField;

  Class.constructorAndGetter();
  dynamic get constructorAndGetter => null;

  factory Class.factoryAndGetter() => new Class.constructorAndGetter();
  dynamic get factoryAndGetter => null;

  factory Class.redirectingFactoryAndGetter() = Class.constructorAndGetter;
  dynamic get redirectingFactoryAndGetter => null;

  Class.constructorAndSetter();
  void set constructorAndSetter(value) {}

  factory Class.factoryAndSetter() => new Class.constructorAndSetter();
  void set factoryAndSetter(value) {}

  factory Class.redirectingFactoryAndSetter() = Class.constructorAndSetter;
  void set redirectingFactoryAndSetter(value) {}
}
