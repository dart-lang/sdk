// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: ExtensionType|constructor#:extensionName=ExtensionType.new*/
extension type ExtensionType(int /*
 extensionThis,
 name=this
*/it) {
  /*member: ExtensionType|constructor#constructor:extensionName=ExtensionType.constructor*/
  ExtensionType.constructor(this./*
   extensionThis,
   name=this
  */it);

  /*member: ExtensionType|constructor#factory:extensionName=ExtensionType.factory*/
  factory ExtensionType.factory(int value) => ExtensionType(value);

  /*member: ExtensionType|constructor#redirectingFactory:extensionName=ExtensionType.redirectingFactory*/
  factory ExtensionType.redirectingFactory(int value) = ExtensionType;

  /*member: ExtensionType|instanceMethod:extensionName=ExtensionType.instanceMethod*/
  int /*
   extensionThis,
   name=this
  */
      instanceMethod() => this.it;

  /*member: ExtensionType|get#instanceGetter:extensionName=ExtensionType.instanceGetter*/
  int get /*
   extensionThis,
   name=this
  */
      instanceGetter => this.it;

  /*member: ExtensionType|set#instanceSetter:extensionName=ExtensionType.instanceSetter*/
  void set /*
   extensionThis,
   name=this
  */
      instanceSetter(int value) {}

  /*member: ExtensionType|staticMethod:extensionName=ExtensionType.staticMethod*/
  static int staticMethod() => 42;

  /*member: ExtensionType|staticGetter:extensionName=ExtensionType.staticGetter*/
  static int get staticGetter => 42;

  /*member: ExtensionType|staticSetter=:extensionName=ExtensionType.staticSetter*/
  static void set staticSetter(int value) {}
}
