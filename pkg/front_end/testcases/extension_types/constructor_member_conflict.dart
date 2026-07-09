// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionType(int it) {
  ExtensionType.constructorAndMethod();
  void constructorAndMethod() {}

  factory ExtensionType.factoryAndMethod() =>
      new ExtensionType.constructorAndMethod();
  void factoryAndMethod() {}

  factory ExtensionType.redirectingFactoryAndMethod() =
      ExtensionType.constructorAndMethod;
  void redirectingFactoryAndMethod() {}

  ExtensionType.constructorAndGetter();
  dynamic get constructorAndGetter => null;

  factory ExtensionType.factoryAndGetter() =>
      new ExtensionType.constructorAndGetter();
  dynamic get factoryAndGetter => null;

  factory ExtensionType.redirectingFactoryAndGetter() =
      ExtensionType.constructorAndGetter;
  dynamic get redirectingFactoryAndGetter => null;

  ExtensionType.constructorAndSetter();
  void set constructorAndSetter(value) {}

  factory ExtensionType.factoryAndSetter() =>
      new ExtensionType.constructorAndSetter();
  void set factoryAndSetter(value) {}

  factory ExtensionType.redirectingFactoryAndSetter() =
      ExtensionType.constructorAndSetter;
  void set redirectingFactoryAndSetter(value) {}
}
