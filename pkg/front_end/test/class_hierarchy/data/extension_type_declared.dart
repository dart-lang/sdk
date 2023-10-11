// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: ExtensionType.id:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.method:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.getter:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.[]:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.staticField:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.staticMethod:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.staticGetter:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.staticField=:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.setter=:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
/*member: ExtensionType.staticSetter=:
 extensionTypeBuilder=ExtensionType,
 isSourceDeclaration
*/
extension type ExtensionType(int id) {
  void method() {}
  int get getter => id;
  void set setter(int value) {}
  int operator[] (int index) => id;
  static int staticField = 42;
  static void staticMethod() {}
  static int get staticGetter => 42;
  static void set staticSetter(int value) {}
}