// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type ExtensionType(int id) {
  /*member: ExtensionType.id:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */

  /*member: ExtensionType.method:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  void method() {}

  /*member: ExtensionType.getter:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  int get getter => id;

  /*member: ExtensionType.setter=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  void set setter(int value) {}

  /*member: ExtensionType.[]:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  int operator[] (int index) => id;

  /*member: ExtensionType.staticField:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  /*member: ExtensionType.staticField=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static int staticField = 42;

  /*member: ExtensionType.staticMethod:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static void staticMethod() {}

  /*member: ExtensionType.staticGetter:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static int get staticGetter => 42;

  /*member: ExtensionType.staticSetter=:
   extensionTypeBuilder=ExtensionType,
   isSourceDeclaration
  */
  static void set staticSetter(int value) {}
}